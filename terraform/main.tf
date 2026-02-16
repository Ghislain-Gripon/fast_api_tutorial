terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
  backend "gcs" {
    bucket = var.remote_state_bucket
    prefix = "prod"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
