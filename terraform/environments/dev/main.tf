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

resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id    = "raw_dataset"
  friendly_name = "raw"
  description   = "Raw data for analytics project"
  location      = "US"

  labels = {
    env = "dev"
  }
}

resource "google_bigquery_dataset" "analytics_dataset" {
  dataset_id    = "analytics_dataset"
  friendly_name = "analytics"
  description   = "Cleaned data for analytics project"
  location      = "US"

  labels = {
    env = "dev"
  }
}

resource "google_service_account" "bqeditor" {
  account_id = "bqeditor"
}

resource "google_storage_bucket" "ingestion" {
  name          = "exemplary-oath-501101-p8-dev-ingestion"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true
}