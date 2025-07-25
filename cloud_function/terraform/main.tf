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

resource "google_storage_bucket" "function_bucket" {
  name     = var.temp_bucket_gcf
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = false
  }
}

# Crear archivo ZIP desde la carpeta src/
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "../function-source.zip"
}

# Subir el ZIP al bucket
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Crear la Cloud Function v2
resource "google_cloudfunctions2_function" "gcs_to_bigquery" {
  name     = var.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    available_memory       = "512M"
    timeout_seconds        = 60
    service_account_email  = var.service_account_email

    environment_variables = {
      BQ_PROJECT = var.bq_project
      BQ_DATASET = var.bq_dataset
      BQ_TABLE   = var.bq_table
    }
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
