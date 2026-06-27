variable "bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string
}

variable "project_name" {
  description = "Project name used for resource tagging."
  type        = string
}

variable "default_root_object" {
  description = "Default object returned by CloudFront."
  type        = string
  default     = "index.html"
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the CloudFront distribution."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
