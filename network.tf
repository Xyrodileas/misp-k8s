# Collect the current region used by the aws provider
data "aws_region" "current" {
}

# Collect the VPC where the k8s cluster is located
data "aws_vpc" "k8s_vpc" {
  tags = "${map("kubernetes.io/cluster/${var.k8s_cluster_name}", "shared")}"
}

# Subnet to deploy RDS (Must be in the same VPC as K8S)
data "aws_subnet_ids" "eks_subnets" {
  vpc_id = data.aws_vpc.k8s_vpc.id
}
