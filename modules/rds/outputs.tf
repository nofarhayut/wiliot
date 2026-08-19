output "endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "address" {
  description = "RDS hostname"
  value       = aws_db_instance.postgres.address
}

output "db_name" {
  description = "Initial database name"
  value       = aws_db_instance.postgres.db_name
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.postgres.id
}

output "username" {
  description = "DB master username"
  value       = var.username
}

output "password" {
  description = "DB master password (generated; lives in encrypted state only)"
  value       = random_password.master.result
  sensitive   = true # never printed in plan/apply output
}
