# Master password is generated (never hard-coded) and exposed only as a
# sensitive Terraform output kept in the encrypted S3 state.
resource "random_password" "master" {
  length  = 24
  special = false # avoid symbols that break connection strings / URLs
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "postgres" {
  name        = "${var.name}-rds"
  description = "Allow Postgres from approved security groups only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-rds" })
}

# count (not for_each) because the source SG IDs come from EKS and are
# unknown at plan time; the list length is known, which is all count needs.
resource "aws_security_group_rule" "ingress_postgres" {
  count                    = length(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.postgres.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
  description              = "Postgres from allowed security group"
}

resource "aws_db_instance" "postgres" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_encrypted       = true # encryption at rest (KMS)
  db_name                 = var.db_name
  username                = var.username
  password                = random_password.master.result
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  vpc_security_group_ids  = [aws_security_group.postgres.id]
  multi_az                = var.multi_az
  publicly_accessible     = false # private only; reachable inside the VPC via the SG
  skip_final_snapshot     = true  # no final snapshot on destroy (dev throwaway)
  backup_retention_period = 1     # minimal automated backups for dev

  tags = var.tags
}
