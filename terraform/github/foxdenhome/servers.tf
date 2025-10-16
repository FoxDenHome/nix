locals {
  servers = {
    FoxDenServers = "member"
  }
}

resource "github_team" "servers" {
  name    = "Servers"
  privacy = "closed"
}

resource "github_team_membership" "engineers" {
  for_each = local.servers
  team_id  = github_team.servers.id

  username = each.key
  role     = each.value
}

resource "github_membership" "servers" {
  for_each = local.servers

  username = each.key
  role     = each.value
}
