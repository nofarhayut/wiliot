variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "Subnet IDs for the cluster (private recommended for nodes)"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane (from iam module)"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for worker nodes (from iam module)"
  type        = string
}

variable "endpoint_public_access" {
  description = "Whether the API server endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
