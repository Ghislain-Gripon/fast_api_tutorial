terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.19.0"
    }
  }
  backend "gcs" {
    prefix = "prod"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
