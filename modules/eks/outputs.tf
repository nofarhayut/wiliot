output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_data" {
  description = "Base64 cluster CA certificate"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group managed by EKS for control-plane <-> node traffic (source SG for RDS access)"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}
