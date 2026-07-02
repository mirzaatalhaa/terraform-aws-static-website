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

variable "aliases" {
  description = "Optional custom domain names for the CloudFront distribution."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.aliases) == 0 ||
      var.certificate_arn != null
    )

    error_message = "certificate_arn must be provided when aliases are configured."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for custom domains. Leave null to use the default CloudFront certificate."
  type        = string
  default     = null
}