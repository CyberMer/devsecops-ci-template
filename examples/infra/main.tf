# Reference Terraform that Trivy's misconfig scanner checks.
# Written to PASS the IaC gate — it shows the secure baseline, not a vuln fixture.

terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

# Namespace with baseline Pod Security enforcement.
resource "kubernetes_namespace" "app" {
  metadata {
    name = "sample-app"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
    }
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "sample-app"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "sample-app" }
    }
    template {
      metadata {
        labels = { app = "sample-app" }
      }
      spec {
        automount_service_account_token = false

        security_context {
          run_as_non_root = true
          run_as_user     = 65532
          fs_group        = 65532
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "app"
          image = "ghcr.io/cybermer/sample-app:latest"

          port {
            container_port = 8080
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            privileged                 = false
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
          }
        }
      }
    }
  }
}
