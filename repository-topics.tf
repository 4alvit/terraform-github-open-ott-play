# Discovery topics for the public projects that shipped without any. Topics are
# kept in their own resource so a repository adopted only for its ruleset can
# receive them without taking ownership of unrelated repository settings.
locals {
  repository_topics = {
    ottplay-control-server = [
      "control-server", "go", "iptv", "kubernetes", "ott", "ottplay", "python"
    ]
    ottplay-core = [
      "es5", "iptv", "javascript", "ott", "ottplay", "shared-core"
    ]
    ottplay-web-vitrine = [
      "here-now", "iptv", "javascript", "ott", "ottplay", "web"
    ]
    ottplay-android = [
      "android", "android-tv", "iptv", "jetpack-compose", "kotlin", "media3", "ott", "ottplay"
    ]
  }
}

resource "github_repository_topics" "discovery" {
  for_each   = local.repository_topics
  repository = each.key
  topics     = each.value
}
