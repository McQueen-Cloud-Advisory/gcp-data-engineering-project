# Development Notes

## Purpose

This document records the implementation history, technical decisions, encountered failures, and next steps for the GCP Data Engineering Project.

It is written to show not only the final architecture, but also how the architecture was developed, tested, and corrected.

## Project Status

The project currently has a working infrastructure foundation, a loaded monthly source sample, and a valid dbt-to-BigQuery connection.

The transformation and automated ingestion layers are still under development.

## Initial Scope

The original architecture considered:

- Terraform;
- multiple deployment environments;
- reusable Terraform modules;
- BigQuery;
- Cloud Storage;
- Artifact Registry;
- Cloud Run Jobs;
- Cloud Scheduler;
- service accounts and IAM;
- dbt;
- GitHub Actions; and
- weather enrichment.

That scope was technically valid but too broad for the first implementation increment.

The project was deliberately reduced to:

1. learn the Terraform lifecycle;
2. provision the minimum warehouse infrastructure;
3. load one source file manually;
4. configure dbt;
5. understand the source data;
6. build transformations; and
7. automate only after the manual flow works.

This prevented infrastructure, ingestion, schema, authentication, and transformation failures from being debugged simultaneously.

## Phase 1: Terraform Fundamentals

### Initial configuration

The first Terraform exercise created:

- one BigQuery dataset; and
- one service account.

The configuration was kept in a simple development root rather than immediately introducing reusable modules.

### Terraform lifecycle validated

The following workflow was successfully tested:

```text
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

A metadata change was also made and reapplied to confirm Terraform could update an existing resource in place.

### Authentication failure

The first apply failed while creating the service account with:

```text
invalid_grant
invalid_rapt
```

The browser and normal Google Cloud CLI sessions had been refreshed, but Terraform was using Application Default Credentials.

The local Application Default Credentials were revoked and recreated. After reauthentication, Terraform successfully created the resources.

### Lesson

Browser authentication, Google Cloud CLI authentication, and Application Default Credentials are related but distinct authentication contexts. Local infrastructure tools may continue using stale ADC credentials even when the user has recently signed into the Cloud Console.

## BigQuery Dataset Access Failure

An inline dataset access block initially granted a service account the BigQuery Data Editor role.

Creation succeeded, but a later update failed because the dataset access configuration was treated as a full policy replacement. The declared policy contained an editor but no directly assigned owner.

BigQuery rejected the update because the resulting dataset policy would not contain a valid owner.

### Resolution

The inline access block was removed for the initial exercise.

Dataset-level access will later be managed separately rather than embedding an incomplete authoritative policy in the dataset resource.

### Lesson

Infrastructure configuration can be authoritative even when it visually appears additive. IAM and access resources require particular care because an update can replace existing policy rather than append a new entry.

## Dataset Destruction Failure

The first dataset destroy failed with a `resourceInUse` error.

A table had been manually created in the dataset to test the update workflow. BigQuery would not allow Terraform to delete the nonempty dataset under the existing configuration.

After confirming the table was disposable and removing it, Terraform successfully destroyed both the dataset and the service account.

### Lesson

Managed resources can contain child objects that prevent deletion. Resource lifecycle behavior should be tested before adopting destroy-and-recreate workflows.

For development resources, force deletion may be acceptable when data is explicitly disposable. It should not be treated as a safe default for persistent environments.

## Phase 2: Minimum Infrastructure

After completing the disposable exercise, Terraform was expanded to provision:

- a raw BigQuery dataset;
- an analytics BigQuery dataset;
- a Cloud Storage ingestion bucket; and
- an ingestion service account.

The plan showed four resources to add, with no changes or destruction. The apply completed successfully.

### Naming decisions

Terraform resource labels use concise purpose-based identifiers.

Cloud resource names use descriptive, environment-aware names and comply with provider naming restrictions.

The ingestion bucket uses:

- Standard storage;
- the `US` location;
- uniform bucket-level access; and
- force deletion during the current disposable development phase.

### Location decision

The Cloud Storage bucket and BigQuery datasets use the same `US` multi-region to reduce avoidable location conflicts between storage and warehouse workloads.

### Module decision

Reusable modules were intentionally postponed.

The current infrastructure is small, and modularizing immediately would hide resource behavior before repeated patterns have emerged. Resources will be extracted into modules when doing so removes actual duplication or creates a meaningful reusable boundary.

## Phase 3: Source Data

One month of airline on-time performance data was selected as the initial development sample.

Using a single month provides enough volume and schema complexity to test the pipeline without introducing the cost and debugging overhead of a complete historical backfill.

### Raw-table loading

BigQuery schema autodetection did not successfully infer the source schema.

The source includes numerous identifiers, indicators, numeric measures, and time-like fields that may contain blanks or inconsistent formatting.

The raw table was therefore loaded with all 62 source columns represented as strings.

### Raw-schema decision

Using strings in the raw layer is intentional for this first implementation.

Advantages:

- source rows are less likely to be rejected during ingestion;
- original values remain visible;
- malformed values can be investigated;
- type logic is centralized in dbt; and
- the staging layer can distinguish invalid conversions from missing values.

Tradeoff:

The raw table does not enforce strong types. Data-quality controls must therefore be implemented immediately downstream.

## Phase 4: dbt Configuration

### Profile location

The local BigQuery connection profile is stored in:

```text
C:\Users\<user>\.dbt\profiles.yml
```

It is intentionally outside the repository.

The profile uses:

- BigQuery;
- OAuth;
- the active Google Cloud project;
- the analytics dataset as the dbt output dataset;
- the `US` location; and
- interactive query priority.

No service-account JSON key is stored or referenced.

### Multiple dbt projects

The local `profiles.yml` supports more than one dbt project by using unique top-level profile names.

The current repository references its profile explicitly from `dbt_project.yml`.

### Deleted quota-project issue

An earlier Google Cloud project had been deleted. Although the dbt profile referenced the correct active project, a debug query attempted to use the deleted project as the Application Default Credentials quota project.

The quota-project configuration had to be updated so Google client libraries stopped attributing the request to the deleted project.

### Project-file errors

Several `dbt_project.yml` issues were encountered:

- using the deprecated or incorrect `source-paths` key;
- supplying an absolute local Windows path;
- including the repository folder twice in relative paths;
- defining `target-path` as a YAML sequence instead of a string; and
- running dbt against an unsaved version of the file.

The final project configuration uses the repository-relative model path:

```text
models
```

The explicit target path was removed because the default is sufficient.

### Lesson

Portable project configuration should use paths relative to `dbt_project.yml`. Local absolute paths make repositories machine-specific and unsuitable for CI.

## Source Declaration

The raw BigQuery table is declared in a source properties file under the dbt model path.

The source definition includes:

- Google Cloud project;
- raw BigQuery dataset;
- source table; and
- descriptions for all 62 columns.

Several indentation errors were corrected while building the YAML hierarchy.

The validated hierarchy is:

```text
sources
└── source
    └── tables
        └── table
            └── columns
                └── column
```

The dbt connection test now completes successfully.

## Repository Hygiene

The root `.gitignore` excludes:

### Terraform-generated or sensitive files

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
*.tfplan
override files
Terraform CLI configuration
crash logs
```

### dbt-generated files

```text
dbt/target/
dbt/logs/
dbt/dbt_packages/
```

The Terraform dependency lock file is committed so provider selection remains reproducible.

The local dbt profile is not stored in the repository.

## Current Architecture

```text
Monthly source file
        |
        | manual upload during initial development
        v
Cloud Storage ingestion bucket
        |
        | manual load during initial development
        v
BigQuery raw dataset
        |
        | declared as a dbt source
        v
dbt staging models
        |
        v
BigQuery analytics dataset
```

Cloud Run automation is intentionally deferred until the source loading and transformation behavior are understood.

## Next Implementation Steps

### 1. Build the first staging model

The first staging model should:

- select from the declared dbt source;
- rename source columns into consistent snake_case;
- convert empty strings to null;
- cast dates and numeric measures;
- standardize binary indicators;
- interpret scheduled and actual flight times;
- retain source traceability; and
- expose invalid conversions.

### 2. Add tests

Initial tests should cover:

- required flight dates;
- required carrier codes;
- required origin and destination codes;
- expected cancellation indicators;
- successful conversion of critical numerical fields;
- accepted categorical values; and
- candidate flight-level uniqueness.

A natural key must be evaluated rather than assumed. Carrier, flight number, date, origin, destination, and scheduled departure may be required to identify a flight record.

### 3. Profile the source data

Before building marts, the project should determine:

- null rates;
- duplicate rates;
- invalid numeric values;
- malformed dates;
- unusual flight times;
- cancellation behavior;
- diverted-flight behavior; and
- differences in row counts between raw and staging.

### 4. Build intermediate models

Potential reusable logic includes:

- normalized scheduled and actual timestamps;
- overnight flight handling;
- cancellation and diversion classification;
- delay-category calculations;
- route identifiers;
- airport-hour aggregation; and
- operational reliability measures.

### 5. Build marts

Planned marts include:

```text
fct_flights
dim_airport
dim_carrier
dim_route
dim_date
mart_airport_reliability_daily
mart_route_performance_monthly
mart_carrier_reliability
mart_delay_causes
```

Final model structure will be based on actual analytical requirements rather than created solely to mimic a generic star schema.

### 6. Automate ingestion

After manual loading and transformation are stable:

```text
Cloud Scheduler
        |
        v
Cloud Run Job
        |
        v
Download monthly source
        |
        v
Cloud Storage
        |
        v
BigQuery raw table
```

The job should support:

- repeatable monthly execution;
- idempotency;
- source-file validation;
- schema validation;
- ingestion metadata;
- duplicate-load prevention;
- logging; and
- explicit failure behavior.

### 7. Add CI/CD

Planned GitHub Actions checks include:

- Terraform formatting;
- Terraform validation;
- Terraform planning;
- dbt project parsing;
- dbt compilation;
- dbt tests against an isolated target; and
- documentation generation.

Authentication should use Workload Identity Federation rather than committed keys.

## Design Principles Demonstrated

### Incremental delivery

The pipeline is being implemented as a series of working vertical slices rather than as one large untested architecture.

### Infrastructure ownership

Cloud resources are created and removed through Terraform so the environment can be reproduced consistently.

### Separation of responsibilities

- Terraform manages infrastructure.
- Cloud Storage preserves source files.
- BigQuery stores raw and modeled data.
- dbt manages warehouse transformation and testing.
- Cloud Run will manage finite batch ingestion.

### Security

Long-lived service-account keys are avoided.

### Cost awareness

The project uses a limited development sample, serverless services, deliberate query execution, and disposable infrastructure during the early learning phase.

### Honest documentation

Completed work, planned work, and unresolved decisions are documented separately. Planned services are not presented as already implemented.

## Hiring-Manager Summary

This project demonstrates the ability to:

- learn a new infrastructure-as-code tool through direct implementation;
- provision and manage Google Cloud resources;
- diagnose cloud authentication and quota-project failures;
- reason about authoritative IAM behavior;
- manage resource dependencies and destruction;
- design separate raw and analytics warehouse layers;
- preserve messy source data before transformation;
- configure dbt against BigQuery;
- document a wide source schema;
- maintain secure repository boundaries; and
- reduce an overambitious architecture into testable delivery increments.

The project is unfinished by design. The repository is intended to show the development process and engineering decisions as the pipeline progresses, rather than publishing only a polished final state.