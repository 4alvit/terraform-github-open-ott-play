output "repositories" {
  description = "Managed repositories"
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
    ottplay_core = {
      name     = github_repository.ottplay_core.name
      html_url = github_repository.ottplay_core.html_url
      ssh_url  = github_repository.ottplay_core.ssh_clone_url
    }
    ottplay_android = {
      name     = github_repository.ottplay_android.name
      html_url = github_repository.ottplay_android.html_url
      ssh_url  = github_repository.ottplay_android.ssh_clone_url
    }
    ottplay_swop = {
      name     = github_repository.ottplay_swop.name
      html_url = github_repository.ottplay_swop.html_url
      ssh_url  = github_repository.ottplay_swop.ssh_clone_url
    }
    ottplay_web_vitrine = {
      name     = github_repository.ottplay_web_vitrine.name
      html_url = github_repository.ottplay_web_vitrine.html_url
      ssh_url  = github_repository.ottplay_web_vitrine.ssh_clone_url
    }
    foss_cloudflare_infrastructure = {
      name     = github_repository.foss_cloudflare_infrastructure.name
      html_url = github_repository.foss_cloudflare_infrastructure.html_url
      ssh_url  = github_repository.foss_cloudflare_infrastructure.ssh_clone_url
    }
  }
}

output "organization_url" {
  description = "Organization URL"
  value       = "https://github.com/${var.github_organization}"
}
