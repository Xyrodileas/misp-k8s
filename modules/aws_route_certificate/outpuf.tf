output "fqdn" {
  value = "${var.subdomain}.${var.route53_zone}"
}

output "aws_dns" {
  value = "${flatten(data.dns_a_record_set.aws_dns_server.*.addrs)}"
}

output "certificate_arn" {
    value= "${aws_acm_certificate.service_certificate.arn}"
}
