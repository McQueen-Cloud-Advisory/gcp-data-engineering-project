terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=7.0, < 8.0"
    }
  }
}
provider "google" {
  project = "exemplary-oath-501101-p8"
  region  = "us-east4"
  zone    = "us-east4-a"
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id    = "example_dataset"
  friendly_name = "test"
  description   = "This is a test description"
  location      = "US"

  labels = {
    env = "dev"
  }

  access {
    role          = "roles/bigquery.dataEditor"
    user_by_email = google_service_account.bqeditor.email
  }
}

resource "google_service_account" "bqeditor" {
  account_id = "bqeditor"
}