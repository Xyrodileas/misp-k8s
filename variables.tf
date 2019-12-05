variable "k8s_cluster_name" {
  type    = "string"
}

variable "route53_zone" {
  type    = "string"
}

variable "MYSQL_DATABASE" {
  type    = "string"
}
variable "MYSQL_USER" {
  type    = "string"
}
variable "MYSQL_ROOT_PASSWORD" {
  type    = "string"
}
variable "MISP_ADMIN_EMAIL" {
  type    = "string"
}

variable "MISP_ADMIN_PASSPHRASE" {
  type    = "string"
}

variable "POSTFIX_RELAY_HOST" {
  type    = "string"
}

variable "TIMEZONE" {
  type    = "string"
}

variable "DATA_DIR" {
  type    = "string"
}

variable "aws_region" {
  type    = "string"
}

variable "authorized_ips" {
  type = string
}

variable "size_db" {
  type = "number"
}
