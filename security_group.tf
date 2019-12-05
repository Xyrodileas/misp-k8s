data "aws_security_groups" "k8s_sg" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.k8s_vpc.id}"]
  }
}

data "aws_security_group" "eks_node_ext" {
  filter {
    name = "tag:Name"
    values = ["${var.k8s_cluster_name}-node-ext-sg"]
  }
}
