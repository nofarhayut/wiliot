variable "name" {
  description = "Name prefix for IAM roles"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
