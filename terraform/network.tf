# 1. Reserve a Static Global IP
resource "google_compute_global_address" "lb_ip" {
  name = "fastapi-lb-ip"
}

# 2. Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  name = "fastapi-cert"
  managed {
    domains = ["ghislaingripon.com", "api.ghislaingripon.com", "test.api.ghislaingripon.com"] # MUST match Route 53
  }
}

# 3. Serverless NEG (Connects LB to Cloud Run)
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "fastapi-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.fastapi.name
  }
}

# 4. Backend Service
resource "google_compute_backend_service" "default" {
  name       = "fastapi-backend"
  protocol   = "HTTPS"
  enable_cdn = false
  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
}

# 5. URL Map (Routing)
resource "google_compute_url_map" "default" {
  name            = "fastapi-url-map"
  default_service = google_compute_backend_service.default.id
}

# 6. HTTPS Proxy
resource "google_compute_target_https_proxy" "default" {
  name             = "fastapi-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
  depends_on       = [google_compute_managed_ssl_certificate.default]
}

# 7. Forwarding Rule (The Entry Point)
resource "google_compute_global_forwarding_rule" "default" {
  name       = "fastapi-lb-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}
