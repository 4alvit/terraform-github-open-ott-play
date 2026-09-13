# Adopt existing GitHub objects into the existing HCP workspace. These addresses
# remain stable after import; no second state owner or resource recreation is used.
import {
  to = github_team.bots
  id = "19138503"
}

import {
  to = github_repository.ottplay_web_vitrine
  id = "ottplay-web-vitrine"
}

import {
  to = github_repository_vulnerability_alerts.ottplay_web_vitrine
  id = "ottplay-web-vitrine"
}

import {
  to = github_repository_dependabot_security_updates.ottplay_web_vitrine
  id = "ottplay-web-vitrine"
}

import {
  to = github_team_repository.bots_profile
  id = "19138503:.github"
}

import {
  to = github_team_repository.bots_ottplay_web_vitrine
  id = "19138503:ottplay-web-vitrine"
}
