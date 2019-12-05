# DNS Zone used to deploy MISP and MISP-Dashboard
data "aws_route53_zone" "managed_zone" {
  name         = "${var.route53_zone}."
  private_zone = false
}

# Name used for MISP and MISP-DASHBOARD's DNS entry
locals {
  k8s_misp_internal_name = "misp"
  k8s_misp_dashboard_internal_name = "misp-dashboard"
}

# DNS Entry for MISP
module "misp_dns_record" {
  source = "./modules/aws_route_certificate"
  subdomain = "${local.k8s_misp_internal_name}"
  route53_zone = "${var.route53_zone}"
}

# DNS Entry for MISP Dashboard
module "misp_dashboard_dns_record" {
  source = "./modules/aws_route_certificate"
  subdomain = "${local.k8s_misp_dashboard_internal_name}"
  route53_zone = "${var.route53_zone}"
}
