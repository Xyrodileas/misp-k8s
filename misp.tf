# Mapping for ports
locals {
  internal_misp_port = 80
  external_misp_port = 80
  zmq_internal_port = 50000
}

# Kubernetes Deployment for misp-dashboard
# Include the container configuration
resource "kubernetes_deployment" "misp" {
  metadata {
    name = "${local.k8s_misp_internal_name}"
    labels = {
      app = "${local.k8s_misp_internal_name}"
    }
  }
  spec {
    selector {
        match_labels = {
            app = "${local.k8s_misp_internal_name}"
        }
    }
    template {
      metadata {
        name = "${local.k8s_misp_internal_name}"
        labels = {
          app = "${local.k8s_misp_internal_name}"
        }
      }
      spec {
        container {
          image = "xyrodileas/misp:latest"
          name  = "${local.k8s_misp_internal_name}"
          port {
            container_port = "${local.internal_misp_port}"
          }
          env {
              name = "MYSQL_HOST"
              value = "${aws_db_instance.misp_db.address}"
          }
          env {
              name  = "MYSQL_DATABASE"
              value = "${aws_db_instance.misp_db.name}"
          }
          env {
              name  = "MYSQL_USER"
              value = "${aws_db_instance.misp_db.username}"
          }
          env {
              name  = "MYSQL_PASSWORD"
              value = "${random_password.password_misp.result}"
          }
          env {
              name  = "MISP_ADMIN_EMAIL"
              value = "${var.MISP_ADMIN_EMAIL}"
          }
          env {
              name  = "MISP_ADMIN_PASSPHRASE"
              value = "${var.MISP_ADMIN_PASSPHRASE}"
          }
          env {
              name  = "MISP_BASEURL"
              value = "https://misp.${var.route53_zone}"
          }
          env {
              name  = "POSTFIX_RELAY_HOST"
              value = "${var.POSTFIX_RELAY_HOST}"
          }
          env {
              name  = "TIMEZONE"
              value = "${var.TIMEZONE}"
          }


        }

      }
    }
  }
}

# Kubernetes Service configuration
# Configure the port mapping between container and ingress point for MISP
resource "kubernetes_service" "misp" {
  metadata {
    name = "${local.k8s_misp_internal_name}-service"
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.misp.metadata.0.labels.app}"
    }
    port {
      port = "${local.external_misp_port}"
      target_port = "${local.internal_misp_port}"
    }
    type= "NodePort"
  }
}

# Kubernetes Service configuration
# Configure the port mapping between container and ingress point for the ZMQ service
resource "kubernetes_service" "misp-zmq" {
  metadata {
    name = "${local.k8s_misp_internal_name}-zmq"
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.misp.metadata.0.labels.app}"
    }
    port {
      port = "${local.zmq_internal_port}"
      target_port = "${local.zmq_internal_port}"
    }
    type= "NodePort"
  }
}

# Kubernetes Ingress configuration
# Configure the external load balancer for access (AWS ALB)
# var.authorized_ips is used to whitelist IP.
resource "kubernetes_ingress" "misp_ingress" {
  metadata {
    name = "${local.k8s_misp_internal_name}-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn" = "${module.misp_dns_record.certificate_arn}"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/inbound-cidrs" = "${join(", ",var.authorized_ips)}"
      "alb.ingress.kubernetes.io/tags" = "Name=misp_tf, Environment=Prod, Product=misp"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
    }
  }

  spec {
    rule {
      host = "${module.misp_dns_record.fqdn}"
      http {
        path {
          backend {
            service_name = "ssl-redirect"
            service_port = "use-annotation"
          }
        }
        path {
          backend {
            service_name = "${kubernetes_service.misp.metadata.0.name}"
            service_port = "${local.external_misp_port}"
          }
        }
      }
    }
  }
}
