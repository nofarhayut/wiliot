variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project/name prefix"
  type        = string
  default     = "wiliot-dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "wiliot-dev"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
