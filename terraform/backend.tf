terraform {
  backend "gcs" {
    bucket  = "terraform-state-gcp-test"
    prefix  = "cloudfunctions/state"
  }
}