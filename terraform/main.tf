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

# --------------------------
# 1. Generar nombre aleatorio para el bucket temporal
# --------------------------
resource "random_id" "bucket_prefix" {
  byte_length = 4
}

# --------------------------
# 2. Crear bucket temporal
# --------------------------
resource "google_storage_bucket" "function_bucket" {
  name                        = "${random_id.bucket_prefix.hex}-gcf-source"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------
# 3. Crear ZIP desde carpeta src/
# --------------------------
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "../function-source.zip"
}

# --------------------------
# 4. Subir ZIP al bucket temporal
# --------------------------
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# --------------------------
# 5. Variables locales para desacoplar función del bucket
# --------------------------
locals {
  function_source_bucket = google_storage_bucket.function_bucket.name
  function_source_object = google_storage_bucket_object.function_source.name
}

# --------------------------
# 6. Crear Cloud Function desacoplada del bucket
# --------------------------
resource "google_cloudfunctions2_function" "gcs_to_bigquery" {
  name     = var.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python310"
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = local.function_source_bucket
        object = local.function_source_object
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
