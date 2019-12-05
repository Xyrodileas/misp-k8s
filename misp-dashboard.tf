# Mapping for ports
locals {
  internal_misp_dashboard_port = 8001
  external_misp_dashboard_port = 80
}

# Kubernetes Deployment for misp-dashboard
# Include the container configuration
resource "kubernetes_deployment" "misp_dashboard" {
  metadata {
    name = "${local.k8s_misp_dashboard_internal_name}"
    labels = {
      app = "${local.k8s_misp_dashboard_internal_name}"
    }
  }
  spec {
    selector {
        match_labels = {
            app = "${local.k8s_misp_dashboard_internal_name}"
        }
    }
    template {
      metadata {
        name = "${local.k8s_misp_dashboard_internal_name}"
        labels = {
          app = "${local.k8s_misp_dashboard_internal_name}"
        }
      }
      spec {
        container {
          image = "xyrodileas/misp-dashboard:latest"
          name  = "${local.k8s_misp_dashboard_internal_name}"
          port {
            container_port = "${local.internal_misp_dashboard_port}"
          }
          env {
              name = "REDISHOST"
              value = "${aws_elasticache_replication_group.redis_misp.primary_endpoint_address}"
          }
          env {
              name  = "REDISPORT"
              value = "${aws_elasticache_replication_group.redis_misp.port}"
          }
          env {
              name  = "MISP_URL"
              value = "${kubernetes_service.misp.metadata[0].name}"
          }
          env {
              name  = "ZMQ_URL"
              value = "${kubernetes_service.misp-zmq.metadata[0].name}"
          }
          env {
              name  = "ZMQ_PORT"
              value = "${local.zmq_internal_port}"
          }

        }

      }
    }
  }
}

# Kubernetes Service configuration
# Configure the port mapping between container and ingress point for the dashboard
resource "kubernetes_service" "misp_dashboard" {
  metadata {
    name = "${local.k8s_misp_dashboard_internal_name}-service"
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.misp_dashboard.metadata.0.labels.app}"
    }
    port {
      port = "${local.external_misp_dashboard_port}"
      target_port = "${local.internal_misp_dashboard_port}"
    }
    type= "NodePort"
  }
}

# Kubernetes Ingress configuration
# Configure the external load balancer for access (AWS ALB)
# var.authorized_ips is used to whitelist IP.
resource "kubernetes_ingress" "misp_dashboard_ingress" {
  metadata {
    name = "${local.k8s_misp_dashboard_internal_name}-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn" = "${module.misp_dashboard_dns_record.certificate_arn}"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/inbound-cidrs" = "${join(", ",var.authorized_ips)}"
      "alb.ingress.kubernetes.io/tags" = "Name=misp_dashboard_tf, Environment=Prod, Product=misp_dashboard"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
    }
  }

  spec {
    rule {
      host = "${module.misp_dashboard_dns_record.fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
        }
        path {
          backend {
            service_name = "${kubernetes_service.misp_dashboard.metadata.0.name}"
            service_port = "${local.external_misp_dashboard_port}"
          }
        }
      }
    }
  }
}
