# DB used by MISP for persistance
resource "aws_db_instance" "misp_db" {
  allocated_storage    = var.size_db
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "${var.MYSQL_DATABASE}"
  username             = "${var.MYSQL_USER}"
  password             = "${random_password.password_misp.result}"
  parameter_group_name = "default.mysql5.7"
  multi_az             = true
  db_subnet_group_name = "${aws_db_subnet_group.eks_db_sub.name}"
  vpc_security_group_ids = ["${data.aws_security_group.eks_node_ext.id}"]
  final_snapshot_identifier = "MISP-DB-Backup"
}

# Random password used for the database
resource "random_password" "password_misp" {
  length = 16
  special = false
}

# DB Subnet Group to deploy RDS
resource "aws_db_subnet_group" "eks_db_sub" {
  name       = "eks_db"
  # Exception here - last subnet is public
  subnet_ids = slice(tolist(data.aws_subnet_ids.eks_subnets.ids), 0, length(data.aws_subnet_ids.eks_subnets.ids) - 1)

  tags = {
    Name = "EKS DB subnet group"
  }
}

# REDIS Database used by MISP-DASHBOARD
resource "aws_elasticache_replication_group" "redis_misp" {
  replication_group_id          = "tf-redis-misp-dashboard"
  replication_group_description = "Redis for MISP dashboard"
  engine                        = "redis"
  engine_version                = "5.0.5"
  node_type                     = "cache.t2.small"
  port                          = 6379
  parameter_group_name          = "default.redis5.0"
  automatic_failover_enabled    = true
  number_cache_clusters         = 2
  security_group_ids = ["${data.aws_security_group.eks_node_ext.id}"]
  subnet_group_name = aws_elasticache_subnet_group.misp_dashboard_subnet_group.name

}

# DB Subnet Group to deploy RDS
resource "aws_elasticache_subnet_group" "misp_dashboard_subnet_group" {
  name       = "redis-misp-dashboard-subnet-group"
  subnet_ids = data.aws_subnet_ids.eks_subnets.ids
}
