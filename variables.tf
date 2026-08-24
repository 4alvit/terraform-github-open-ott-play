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

variable "billing_email" {
  description = "Organization billing email"
  type        = string
  sensitive   = true
}
