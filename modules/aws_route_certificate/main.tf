data "aws_route53_zone" "managed_zone" {
  name         = "${var.route53_zone}."
  private_zone = false
}

data "dns_a_record_set" "aws_dns_server" {
  count = "${length(data.aws_route53_zone.managed_zone.name_servers)}"
  host = "${data.aws_route53_zone.managed_zone.name_servers[count.index]}"
}

resource "aws_acm_certificate" "service_certificate" {
  domain_name       = "${var.subdomain}.${var.route53_zone}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.service_certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.service_certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.managed_zone.id}"
  records = ["${aws_acm_certificate.service_certificate.domain_validation_options.0.resource_record_value}"]
  ttl     = 10
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.service_certificate.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
