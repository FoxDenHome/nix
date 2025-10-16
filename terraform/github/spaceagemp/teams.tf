locals {
  members = {
    Doridian    = "admin",
    SimonSchick = "admin",
    TomyLobo    = "member",
    mjohnson9   = "member",
  }
}

resource "github_team" "engineers" {
  name    = "Engineers"
  privacy = "closed"
}

resource "github_team_membership" "engineers" {
  for_each = local.members
  team_id  = github_team.engineers.id

  username = each.key
  role     = (each.value == "admin") ? "maintainer" : "member"
}

resource "github_membership" "members" {
  for_each = local.members

  username = each.key
  role     = each.value
}
