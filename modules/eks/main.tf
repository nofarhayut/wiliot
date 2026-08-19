resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true # nodes reach the API server over the private network
  }

  tags = var.tags
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1 # roll nodes one at a time during version upgrades
  }

  tags = var.tags
}

# NOTE: IRSA (OIDC provider) intentionally omitted here. Add it in the Helm/
# task-2 phase when the AWS Load Balancer Controller and Airflow service
# accounts need to assume IAM roles — that is where its purpose is concrete.
