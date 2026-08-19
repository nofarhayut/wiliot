variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten (IMMUTABLE or MUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Keep only the most recent N images"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
