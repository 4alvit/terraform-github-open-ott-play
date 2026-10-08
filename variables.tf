variable "github_organization" {
  description = "GitHub organization name"
  type        = string
  default     = "open-ott-play"
}

variable "github_token" {
  description = "GitHub Personal Access Token with repo/admin:repo_hook/admin:org scopes"
  type        = string
  sensitive   = true
}

# Retained input for existing workspace compatibility; it does not grant access or create resources.
# tflint-ignore: terraform_unused_declarations
variable "billing_email" {
  description = "Organization billing email"
  type        = string
  sensitive   = true
  default     = null
}
