output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_username" {
  description = "DB master username"
  value       = module.rds.username
}

output "rds_password" {
  description = "DB master password (sensitive; read with: terraform output -raw rds_password)"
  value       = module.rds.password
  sensitive   = true
}
