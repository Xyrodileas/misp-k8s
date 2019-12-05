#
# Provider Configuration
#
terraform {
  required_version = ">= 0.11.11"
  backend "s3" {
  }
}


provider "aws" {
  region = "${var.aws_region}"
}

# Path to the kube config file to access to k8s.
provider "kubernetes" {
  config_context = "aws"
  config_path = "/tmp/kubeconfig"
}
