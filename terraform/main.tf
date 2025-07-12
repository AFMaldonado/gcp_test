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

# Bucket temporal para subir el ZIP 
resource "random_id" "bucket_prefix" {
  byte_length = 4
}

resource "google_storage_bucket" "function_bucket" {
  name                        = "${random_id.bucket_prefix.hex}-gcf-source"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = false
  }
}

# Crear ZIP localmente
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "../function-source.zip"
}

# Subir el ZIP 
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Cloud Function desacoplada: bucket y object como variables
resource "google_cloudfunctions2_function" "gcs_to_bigquery" {
  name     = var.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = var.function_source_bucket   # 👈 Variable
        object = var.function_source_object   # 👈 Variable
      }
    }

    environment_variables = {
      BQ_PROJECT = var.bq_project
      BQ_DATASET = var.bq_dataset
      BQ_TABLE   = var.bq_table
    }
  }

  service_config {
    available_memory       = "256M"
    timeout_seconds        = 60
    service_account_email  = var.service_account_email
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

