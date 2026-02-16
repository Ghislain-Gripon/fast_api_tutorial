resource "google_cloud_run_v2_service" "fastapi" {
  name     = var.cloud_run_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Only LB can reach this

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/${var.artifact_registry_id}/fastapi-image:latest"
      ports {
        container_port = 8080
      }
    }
  }
}

# Allow the Load Balancer to invoke Cloud Run
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.fastapi.name
  location = google_cloud_run_v2_service.fastapi.location
  role     = "roles/run.invoker"
  member   = "allUsers" # Valid because the "ingress" setting above blocks direct internet access
}
