locals {
  roles = toset([
    "roles/run.admin",
    "roles/run.developer",
    "roles/run.viewer",
    "roles/run.invoker",
    "roles/iam.serviceAccountTokenCreator",
    "roles/artifactregistry.writer"
  ])
}

data "google_compute_default_service_account" "default" {
}

# Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
}

resource "google_project_iam_member" "cloud_run_user" {
  project  = var.project
  for_each = local.roles
  role     = each.value
  member   = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.fastapi.name
  location = google_cloud_run_v2_service.fastapi.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${data.google_compute_default_service_account.default.email}" # Valid because the "ingress" setting above blocks direct internet access
}

# Workload Identity Pool (Connects GitHub to GCP)
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-wif-pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "fastapi"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.repository"       = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  attribute_condition = "assertion.repository_owner_id == '55950736' && assertion.repository_id == '1157436605'"
}

# Allow your specific GitHub Repo to impersonate the Service Account
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/Ghislain-Gripon/fast_api_tutorial"
}

# Allow the Load Balancer to invoke Cloud Run
output "wif_provider_name" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  value = google_service_account.github_actions.email
}
