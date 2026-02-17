resource "google_cloud_run_v2_service" "fastapi" {
  name                = var.cloud_run_service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Only LB can reach this
  deletion_protection = false

  template {
    service_account                  = google_service_account.github_actions.email
    max_instance_request_concurrency = 20
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      env {
        name  = "ENV"
        value = "PROD"
      }
      image = "${var.region}-docker.pkg.dev/${var.project}/${var.artifact_registry_id}/fastapi-image:latest"
      ports {
        container_port = 8080
      }
    }
  }
}
