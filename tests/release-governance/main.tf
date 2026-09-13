terraform {
  required_version = ">= 1.15.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "github_organization" {
  type    = string
  default = "release-contract-fixture"
}
