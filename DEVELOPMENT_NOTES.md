# Development Notes

## Purpose

This document records the implementation history, technical decisions, encountered failures, and next steps for the GCP Data Engineering Project.

It is written to show not only the final architecture, but also how the architecture was developed, tested, and corrected.

## Project Status

The project currently has a working first vertical slice:

```text
Terraform-provisioned Google Cloud infrastructure
        ↓
Cloud Storage landing bucket
        ↓
Raw BigQuery table
        ↓
dbt source declaration
        ↓
dbt staging model
        ↓
Analytics BigQuery dataset
        ↓
dbt tests
        ↓
notebook-based staging validation
        ↓
dbt fact model
        ↓
fact-level dbt tests
```

The infrastructure foundation, raw data load, dbt source declaration, first staging model, initial dbt tests, first notebook-based validation pass, first fact model, and initial fact-level tests are complete.

The automated ingestion, intermediate models, marts, expanded testing, CI/CD, and Cloud Run scheduling layers are still under development.

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

## Phase 5: First dbt Staging Model

The first dbt staging model was created for the airline on-time performance source table.

The model reads from the raw BigQuery table and writes to the analytics dataset.

### Staging model responsibilities

The staging model currently performs the following transformations:

- trims string fields;
- converts blank strings to nulls;
- safely casts numeric-looking source fields to `NUMERIC`;
- parses the flight date from a timestamp-like string into a true date field;
- converts cancellation and diversion indicators into boolean fields;
- standardizes raw source names into cleaner staging names; and
- preserves one row per raw source record.

### Source data issues encountered

Several source-data issues appeared immediately during staging development.

#### Header row loaded as data

The first raw table load accidentally included the CSV header row as a data row. This caused BigQuery to fail when trying to cast the literal value `QUARTER` as a numeric field.

The table was reloaded with the header row skipped rather than modifying the source file manually.

This preserved the source-file format and established the correct future ingestion behavior.

#### Date values stored as timestamp-like strings

The `FL_DATE` field appeared as values such as:

```text
1/1/2026 12:00:00 AM
```

A direct date cast was not appropriate because the value included a time component.

The staging model parses the value using the known datetime format and converts it into a true date field.

#### Numeric fields stored with decimal formatting

Several fields that are logically integer-like appeared in the source as decimal-formatted strings, such as:

```text
-5.00
0.00
1.00
```

Direct casts to integer types failed. The first staging model therefore uses `NUMERIC` for source fields that appear numeric.

Integer tightening may occur later after profiling confirms which fields are safe to narrow.

#### Boolean indicators stored as numeric strings

Cancellation and diversion fields were represented as numeric indicators.

The staging model converts these fields into boolean values:

```text
1 → TRUE
0 → FALSE
```

Unexpected or malformed values become null, allowing tests and profiling to surface data-quality issues rather than hiding them.

### Staging design decision

The staging model uses defensive conversion patterns rather than strict casts.

This is intentional. The raw table preserves source values as strings, while the staging model introduces meaning through controlled parsing, trimming, null handling, and safe casting.

The goal is to prevent one malformed value from breaking the entire model while still making data-quality issues visible.

## Phase 6: Initial dbt Tests

A staging model properties file was added for `stg_bts_on_time_performance`.

Initial tests were added for critical fields:

- flight date;
- marketing carrier;
- origin airport;
- destination airport;
- cancellation flag; and
- diversion flag.

All initial tests passed.

### Initial test scope

The first tests are intentionally simple. They confirm that the staging model produces non-null values for fields that should be required for basic flight-level analysis.

The next testing increment should add:

- accepted values for boolean fields;
- row-count comparison between raw and staging;
- invalid conversion checks;
- duplicate candidate-key checks;
- null-rate checks for important operational fields; and
- source freshness or ingestion-batch checks after automated ingestion exists.

### Lesson

Passing tests do not prove the model is complete. They prove that the first validation layer exists and can be expanded.

This is an important distinction. The project now has a working testing pattern, but the data-quality suite is still immature.

## Phase 7: Notebook-Based Staging Validation

A development notebook was added under the repository's `notebooks` directory to preserve the first staging-validation analysis.

The notebook is intended to be a development and validation artifact, not a production pipeline component.

Planned location:

```text
notebooks/01_staging_validation.ipynb
```

### Notebook purpose

The notebook validates the first raw-to-staging transformation before downstream fact and mart models are built.

The validation focuses on:

- row-count preservation from raw to staging;
- column-count preservation for the current first staging pass;
- flight-date parsing;
- numeric conversion behavior;
- boolean conversion behavior;
- required-field null checks;
- candidate grain analysis; and
- documentation of unresolved natural-key limitations.

### Notebook scope decision

The notebook is intentionally committed as the source `.ipynb` artifact.

HTML and PDF exports were considered but were not adopted as required project artifacts.

The HTML export path encountered notebook rendering issues related to rich widget metadata. The direct PDF export path required a local LaTeX toolchain and additional package installation. Since the repository already preserves the notebook itself, exported HTML and PDF files were not treated as necessary deliverables.

### BigQuery Notebook environment

BigQuery Notebooks were used to speed up exploratory validation and preserve the results as reviewable evidence.

To create and use the notebook runtime, the development environment required:

- BigQuery Unified API enabled;
- private services access enabled on the default VPC;
- Private Google Access enabled on the `us-east4` subnet used by the notebook runtime; and
- notebook runtime creation in `us-east4`.

This configuration is acceptable for the current development exercise. It is not being presented as a production networking pattern.

A production environment would require more deliberate network design, subnet selection, IAM boundaries, private connectivity review, and controls around access to Google APIs.

### Validation structure decision

Some numeric validation checks were intentionally written as separate notebook cells instead of being abstracted into reusable functions.

For this one-off profiling exercise, readability, speed, and ease of review were prioritized over abstraction. If the checks become recurring validation logic, they should be refactored into reusable notebook functions or promoted into dbt tests.

### Row and column validation

The notebook validates that the current staging model preserves both row count and column count.

This is valid for the current first staging pass because the staging model standardizes and types columns but does not intentionally add, drop, or combine source columns.

This validation expectation may change later. Future intermediate, fact, and mart models should not be expected to preserve raw column count.

### Conversion validation

The notebook checks whether populated raw values became null unexpectedly after staging conversion.

Validation areas include:

- flight-date parsing;
- numeric field conversion;
- boolean conversion for cancellation and diversion indicators; and
- unexpected null behavior in required fields.

The purpose is not merely to confirm that dbt runs. The purpose is to prove that the staging model did not silently lose source values during type conversion.

### Candidate grain analysis

A candidate natural grain was evaluated before building the first fact model.

Initial grain fields included:

- flight date;
- operating carrier;
- scheduled operating carrier flight number;
- origin;
- destination; and
- scheduled departure time.

The candidate grain was then expanded with additional available fields such as:

- marketing carrier;
- scheduled arrival time; and
- duplicate indicator.

The expanded natural key reduced duplicate candidate-key records substantially but did not fully eliminate them.

Manual inspection showed that the remaining duplicate-key rows were associated with Alaska Airlines records where `sch_op_carrier_fl_num` was null. This weakened the available natural key because the only flight-number-like field in the current source schema was not consistently populated for those records.

Adding `is_cancelled` made the remaining rows unique. However, cancellation status is an operational outcome field, not a natural identifier. It should not be used as part of the business grain solely to force uniqueness.

### Grain decision

The staging validation supports the following current fact-table grain:

```text
one row per source flight record
```

rather than:

```text
one row per uniquely identifiable scheduled flight
```

Because the available natural identifiers do not fully guarantee uniqueness, the first fact model should use a generated surrogate key while retaining the natural-key fields for traceability and analysis.

### Lesson

A natural key should be tested, not assumed.

The analysis showed that the source data does not provide a consistently populated natural flight identifier for every record in the current sample. Documenting that limitation and using a surrogate key is a stronger modeling decision than adding outcome fields to the grain simply to make uniqueness tests pass.


## Phase 8: First Fact Model

The first fact model, `fct_flights`, was added after the staging model, dbt tests, and notebook-based candidate-grain analysis were completed.

The fact model reads from the dbt staging model rather than directly from the raw source table. This keeps the warehouse layers separated:

```text
raw source table
        ↓
dbt staging model
        ↓
dbt fact model
```

### Fact-model purpose

The first fact model creates an analytics-ready flight-record table from the validated staging model.

The model responsibilities include:

- preserving one row per source flight record;
- generating a stable surrogate key;
- retaining natural identifier fields for traceability;
- selecting trusted staged fields for analysis;
- tightening confirmed whole-number fields to `INT64`;
- carrying cancellation and diversion indicators forward as boolean fields;
- retaining delay, duration, distance, airport, route, and carrier fields; and
- providing a stable base for marts and downstream reporting.

### Fact grain

The fact table is defined at the following grain:

```text
one row per source flight record
```

This grain was selected because the available natural identifiers did not fully guarantee uniqueness for every record in the current source sample.

A candidate natural key was evaluated using available carrier, date, origin, destination, scheduled-time, airport-sequence, and duplicate-indicator fields. The expanded key reduced duplicate records substantially but did not fully eliminate them.

Manual inspection showed that the remaining duplicate-key records were associated with rows where `sch_op_carrier_fl_num` was null. Adding `is_cancelled` made the remaining rows unique, but cancellation status is an operational outcome field rather than a natural identifier.

Because of this, the fact model uses a generated surrogate key while preserving the available natural-key fields for analysis and traceability.

### Surrogate-key decision

The surrogate key is used to identify fact-table records at the source-record level.

This does not mean the project is treating cancellation status as part of the natural business grain. Instead, the surrogate key supports row-level uniqueness where the source data does not provide a consistently populated natural flight identifier.

This distinction is important:

```text
Natural grain: not fully reliable with available source fields
Fact-table grain: one row per source flight record
Record identity: generated surrogate key
```

### Type tightening

The staging model keeps parsed numeric fields as `NUMERIC` to safely handle raw string inputs and source formatting variability.

The fact model tightens fields with confirmed whole-number analytical meaning to `INT64`, including airport identifiers, date parts, delay measures, elapsed-time measures, distance fields, and diversion counts.

Time-code fields remain as cleaned strings for now. Fields such as `crs_dep_time`, `dep_time`, `wheels_off`, `wheels_on`, `crs_arr_time`, `arr_time`, and `first_dep_time` require dedicated handling because airline time values may appear in compact forms such as:

```text
5
55
1230
2400
```

Time normalization will be handled later in a dedicated intermediate model rather than being forced into the first fact model.

### Fact model tests

Initial dbt tests were added for `fct_flights`.

The tests validate:

- surrogate key non-nullness;
- surrogate key uniqueness;
- row-count consistency with the staging model; and
- non-null values for core analytical fields.

All fact model tests passed.

### Lesson

The fact model was not created by assuming the source data had a clean natural key.

The grain was evaluated first, the source limitation was documented, and the model was designed around a surrogate key where the available natural identifiers were insufficient. This preserves row-level analytical usability without pretending the source provides a perfect scheduled-flight identifier.

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

### Notebook-generated files

```text
.ipynb_checkpoints/
notebooks/.ipynb_checkpoints/
```

The notebook itself is a committed validation artifact. Checkpoint files and local runtime artifacts are not committed.

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
dbt staging model
        |
        | type conversion, trimming, null handling, date parsing, boolean standardization
        v
Validated staging table
        |
        | dbt tests and notebook-based profiling
        v
dbt fact model: fct_flights
        |
        | surrogate key generation, type tightening, fact-level tests
        v
Tested flight-record fact table
```

Cloud Run automation is intentionally deferred until the source loading, schema behavior, and transformation logic are understood.

The current pipeline is not yet fully automated, but the core data flow has been proven manually from raw source data into a tested staging layer and a tested flight-record fact model.

## Next Implementation Steps

### 1. Build the first business-facing mart

The next modeling increment should build a mart from `fct_flights`.

Recommended first mart:

```text
mart_route_performance_monthly
```

This mart should convert the tested flight-record fact table into a business-facing analytical output.

Potential measures include:

- total flights;
- completed flights;
- cancelled flights;
- cancellation rate;
- diverted flights;
- diversion rate;
- average departure delay;
- average arrival delay;
- on-time arrival rate;
- average elapsed time;
- average air time;
- average distance; and
- delay-cause totals.

Potential grouping fields include:

- flight month;
- marketing carrier;
- operating carrier;
- origin;
- destination;
- route; and
- airport sequence identifiers.

This mart is a better next step than automation because it proves that the modeled data can support useful analytical questions.

### 2. Strengthen dbt tests

The current dbt test suite now covers the staging model and the first fact model.

Planned testing improvements include:

- accepted values for boolean fields;
- accepted ranges for month, day, quarter, and day-of-week fields;
- non-null tests for route-defining fields;
- relationship tests once dimension tables exist;
- mart-level tests for derived metrics;
- custom tests for failed casts or invalid source values; and
- source freshness or ingestion-batch checks after automated ingestion exists.

### 3. Build intermediate models when the logic earns it

Intermediate models are intentionally deferred until reusable or complex business logic emerges.

Likely intermediate models include:

```text
int_flights_with_normalized_times
int_flights_with_delay_categories
int_flights_with_route_keys
int_flights_with_operational_status
```

The first strong candidate is a time-normalization model because airline time codes require special handling.

Fields requiring later handling include:

```text
crs_dep_time
dep_time
wheels_off
wheels_on
crs_arr_time
arr_time
first_dep_time
```

These values may be stored in compact formats such as:

```text
5
55
1230
2400
```

Time normalization should be handled carefully, especially for overnight flights and arrival dates that may roll into the next day.

### 4. Build dimensions

Potential dimension models include:

```text
dim_airport
dim_carrier
dim_route
dim_date
```

These should be created when they support specific marts or reduce repeated logic.

The project should avoid creating a generic star schema solely for appearance. Dimensional structure should follow actual analytical use cases.

### 5. Build additional marts

Planned marts include:

```text
mart_airport_reliability_daily
mart_route_performance_monthly
mart_carrier_reliability
mart_delay_causes
```

Final mart structure will be based on actual analytical requirements and validated source behavior.

### 6. Automate ingestion

After manual loading, staging, fact modeling, and initial marts are stable:

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

### Validated data modeling

The project tests assumptions about grain and natural keys before building downstream models.

When the available natural identifiers did not fully guarantee uniqueness, the fact model used a generated surrogate key and documented the source limitation rather than forcing an outcome field into the business grain.

### Honest documentation

Completed work, planned work, and unresolved decisions are documented separately. Planned services are not presented as already implemented.

## Summary

This project demonstrates the ability to:

- learn a new infrastructure-as-code tool through direct implementation;
- provision and manage Google Cloud resources with Terraform;
- validate the full Terraform lifecycle, including create, update, and destroy behavior;
- diagnose cloud authentication, Application Default Credentials, and quota-project issues;
- reason about authoritative IAM and BigQuery dataset-access behavior;
- manage resource dependencies and deletion constraints;
- design separate raw and analytics warehouse layers;
- preserve messy source data before transformation;
- load real public data into BigQuery;
- configure dbt against BigQuery using OAuth instead of committed service-account keys;
- declare and document a wide raw source schema;
- build a first dbt staging model;
- safely parse dates, numeric values, strings, and boolean indicators from raw source data;
- add and run dbt tests against the staging layer;
- use a notebook to validate staging output and document modeling decisions;
- evaluate candidate natural keys rather than assuming grain;
- recognize when available source identifiers are insufficient and justify surrogate-key usage;
- build a first fact model from a validated staging layer;
- tighten analytical numeric fields from defensive staging types into fact-table types;
- add and pass fact-level dbt tests;
- maintain secure repository boundaries through `.gitignore`;
- reduce an overambitious architecture into testable delivery increments; and
- document not just what worked, but what failed and how it was corrected.

The project is unfinished by design. The repository is intended to show the development process and engineering decisions as the pipeline progresses, rather than publishing only a polished final state.

The current milestone is the first working vertical slice plus modeled warehouse output: Terraform-provisioned infrastructure, raw data loaded into BigQuery, dbt source declaration, staging transformation, analytics-layer output, passing staging tests, notebook-based staging validation, a tested `fct_flights` fact model, and a documented surrogate-key decision.