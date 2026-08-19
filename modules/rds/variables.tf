variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS lives"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach Postgres on 5432 (e.g. EKS cluster SG)"
  type        = list(string)
}

variable "engine_version" {
  description = "PostgreSQL major version (AWS selects the minor)"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "wiliot"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "wiliot_admin"
}

variable "multi_az" {
  description = "Deploy the DB across multiple AZs for high availability"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
