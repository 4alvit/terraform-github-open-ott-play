output "repositories" {
  description = "Created repositories"
  value = {
    profile = {
      name     = github_repository.profile.name
      html_url = github_repository.profile.html_url
      ssh_url  = github_repository.profile.ssh_clone_url
    }
    ottplay_foss = {
      name     = github_repository.ottplay_foss.name
      html_url = github_repository.ottplay_foss.html_url
      ssh_url  = github_repository.ottplay_foss.ssh_clone_url
    }
  }
}

output "organization_url" {
  description = "Organization URL"
  value       = "https://github.com/${var.github_organization}"
}
