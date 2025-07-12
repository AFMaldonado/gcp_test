terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Referencia al bucket y objeto ZIP ya existente
data "google_storage_bucket" "function_bucket" {
  name = var.function_source_bucket
}

data "google_storage_bucket_object" "function_source" {
  name   = var.function_source_object
  bucket = data.google_storage_bucket.function_bucket.name
}

# Crear la Cloud Function desacoplada del bucket
resource "google_cloudfunctions2_function" "gcs_to_bigquery" {
  name     = var.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = data.google_storage_bucket.function_bucket.name
        object = data.google_storage_bucket_object.function_source.name
      }
    }

    environment_variables = {
      BQ_PROJECT = var.bq_project
      BQ_DATASET = var.bq_dataset
      BQ_TABLE   = var.bq_table
    }
  }

  service_config {
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = var.service_account_email
  }

  event_trigger {
    event_type     = "google.cloud.storage.object.v1.finalized"
    trigger_region = var.region

    event_filters {
      attribute = "bucket"
      value     = var.trigger_bucket
    }
  }
}
