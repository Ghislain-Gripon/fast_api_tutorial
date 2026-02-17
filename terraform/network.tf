
resource "google_compute_global_address" "lb_ip" {
  name = "fastapi-lb-ip"
}

resource "google_compute_managed_ssl_certificate" "default1" {
  name = "fastapi-cert-api"
  lifecycle {
    create_before_destroy = true
  }
  managed {
    domains = ["test.api.ghislaingripon.com"] # MUST match Route 53
  }
}

resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "fastapi-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.fastapi.name
  }
}

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

resource "google_compute_target_https_proxy" "default" {
  name             = "fastapi-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default1.id]
  depends_on       = [google_compute_managed_ssl_certificate.default1]
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "fastapi-lb-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}
