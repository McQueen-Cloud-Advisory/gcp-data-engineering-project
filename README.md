# GCP Data Engineering Project

An end-to-end data engineering project using Google Cloud, Terraform, BigQuery, and dbt to build a repeatable analytics pipeline for U.S. airline on-time performance data.

> **Status:** In development. The infrastructure foundation and initial dbt configuration are complete. Data transformation and automated ingestion are being built incrementally.

## Project Objective

The objective of this project is to build a production-minded data pipeline that:

1. provisions cloud infrastructure through Terraform;
2. lands raw airline performance data in Cloud Storage;
3. loads source data into BigQuery;
4. transforms and validates the data with dbt;
5. produces analytics-ready models for flight reliability analysis; and
6. automates ingestion and deployment through managed Google Cloud and CI/CD services.

The project is intentionally being developed in small, testable increments rather than assembling a large generated architecture before its individual components have been validated.

## Planned Architecture

```text
Bureau of Transportation Statistics data
                    |
                    v
              Cloud Run Job
                    |
                    v
        Cloud Storage landing bucket
                    |
                    v
          BigQuery raw dataset
                    |
                    v
       dbt staging and transformation
                    |
                    v
       BigQuery analytics dataset
                    |
                    v
     Analytics marts and reporting
```

The initial implementation uses a manually uploaded monthly source file so that the source schema and transformation requirements can be understood before ingestion is automated.

## Technology Stack

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure provisioning and lifecycle management |
| Google Cloud Storage | Landing zone for source files |
| BigQuery | Raw and analytics data warehouse |
| dbt | Transformation, documentation, lineage, and data testing |
| Google Cloud IAM | Service identities and access management |
| Cloud Run Jobs | Planned containerized batch ingestion |
| Cloud Scheduler | Planned recurring ingestion trigger |
| Artifact Registry | Planned storage for ingestion container images |
| GitHub Actions | Planned validation and deployment automation |

## Current Progress

### Completed

- Created the repository and initial project structure.
- Configured Terraform with the Google Cloud provider.
- Provisioned and validated:
  - a raw BigQuery dataset;
  - an analytics BigQuery dataset;
  - a Cloud Storage ingestion bucket; and
  - an ingestion service account.
- Tested the complete Terraform lifecycle:
  - format;
  - initialize;
  - validate;
  - plan;
  - apply;
  - update; and
  - destroy.
- Loaded one month of airline on-time performance data into BigQuery.
- Configured dbt Core for BigQuery using local OAuth authentication.
- Created a dbt source declaration for the raw airline table.
- Documented all 62 source columns.
- Confirmed the dbt project and BigQuery connection with `dbt debug`.
- Added Git exclusions for Terraform state, local provider files, dbt build artifacts, and logs.

### In Progress

- Building the first dbt staging model.
- Converting raw string fields into validated analytical data types.
- Defining source and staging data-quality tests.
- Establishing consistent handling for nulls, malformed values, dates, and flight-time fields.

### Planned

- Intermediate transformation models.
- Dimensional and analytics-ready marts.
- Incremental monthly ingestion.
- Containerized ingestion with a Cloud Run Job.
- Scheduled execution through Cloud Scheduler.
- NOAA weather enrichment.
- CI validation for Terraform and dbt.
- Workload Identity Federation for keyless GitHub Actions authentication.
- Architecture and data-lineage documentation.

## Repository Structure

```text
.
├── .gitignore
├── README.md
├── DEVELOPMENT_NOTES.md
├── terraform/
│   └── environments/
│       └── dev/
│           ├── main.tf
│           └── .terraform.lock.hcl
└── dbt/
    ├── dbt_project.yml
    └── models/
        ├── staging/
        │   └── sources.yml
        ├── intermediate/
        └── marts/
```

The structure will evolve as the project develops. Reusable Terraform modules and additional deployment environments will be introduced only when the implementation creates a real need for them.

## Data Source

The initial source is one month of U.S. airline on-time performance data.

The raw file contains flight-level operational fields such as:

- flight date;
- reporting carrier;
- flight number;
- origin and destination;
- scheduled and actual departure times;
- arrival times;
- cancellation and diversion indicators;
- elapsed time and distance; and
- attributed delay categories.

The initial raw table preserves all source fields as strings. Data types and business rules are applied in the dbt staging layer so malformed source values can be identified explicitly rather than rejected or silently altered during ingestion.

## Data-Layer Design

```text
Raw source table
        |
        v
Staging models
        |
        v
Intermediate models
        |
        v
Analytics marts
```

### Raw

The raw dataset preserves the source structure with minimal modification.

### Staging

Staging models will:

- rename source columns consistently;
- convert blank strings to nulls;
- cast values into appropriate types;
- standardize dates, indicators, codes, and time values;
- identify invalid conversions; and
- retain traceability to the original source.

### Intermediate

Intermediate models will contain reusable transformation logic, joins, and derived operational measures.

### Marts

Planned analytical outputs include:

- flight-level performance facts;
- airport reliability;
- route reliability;
- carrier performance;
- cancellation analysis;
- delay-cause analysis; and
- weather-related disruption analysis.

## Infrastructure Design

Terraform currently manages the minimum infrastructure required to support development:

- raw BigQuery dataset;
- analytics BigQuery dataset;
- Cloud Storage ingestion bucket; and
- ingestion service account.

The configuration was intentionally kept in a simple root module while the underlying resources and Terraform workflow were being learned. Modularization will occur after repeated infrastructure patterns emerge.

This avoids creating abstractions before the resource relationships are understood.

## Security Approach

The project does not store service-account JSON keys in the repository.

Local Terraform and dbt development use Google Application Default Credentials and OAuth. Future CI/CD automation is planned to use short-lived credentials through Workload Identity Federation rather than persistent service-account keys.

The repository excludes:

- Terraform state;
- local Terraform provider artifacts;
- local variable files;
- saved Terraform plans;
- dbt compiled output;
- dbt logs; and
- local dbt profiles.

## Cost Management

The project is being developed with cost control in mind:

- infrastructure is provisioned and removed through Terraform;
- only a limited source sample is being used during initial development;
- BigQuery queries will be scoped carefully;
- managed and serverless services are preferred;
- Cloud Run Jobs will be used for finite batch workloads; and
- production-scale historical ingestion will not begin until the transformation design is validated.

## Local Development

### Prerequisites

- Google Cloud project
- Google Cloud CLI
- Terraform
- dbt with BigQuery support
- Git
- authenticated Google Application Default Credentials

### Terraform workflow

From the active Terraform root:

```text
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

Infrastructure should always be reviewed through the Terraform plan before applying changes.

### dbt workflow

The local dbt profile is stored outside the repository in the user's `.dbt` directory.

From the folder containing `dbt_project.yml`:

```text
dbt debug
```

Additional model build and test commands will be documented as the transformation layer is implemented.

## Engineering Principles

This project follows several practical principles:

- Infrastructure should be reproducible.
- Raw data should remain traceable to its source.
- Transformations should be explicit and testable.
- Credentials should not be committed.
- Automation should follow a proven manual workflow.
- Cloud services should have a clear architectural purpose.
- Abstraction should follow repetition, not precede understanding.
- Documentation should reflect what has actually been implemented.

## Development Notes

Detailed implementation decisions, troubleshooting history, and planned work are maintained in [`DEVELOPMENT_NOTES.md`](DEVELOPMENT_NOTES.md).

## Disclaimer

This is an independent portfolio and learning project. It is not affiliated with or endorsed by any airline, government agency, employer, or cloud provider.