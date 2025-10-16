locals {
  members = {
    Doridian     = "admin",
    Crashdoom    = "admin",
    TomyLobo     = "admin",
    Alconchloe   = "member",
    mjohnson9    = "member",
    foxbukkit-ci = "member",
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

resource "github_team" "ci" {
  name    = "CI"
  privacy = "closed"
}

resource "github_team_membership" "ci" {
  for_each = toset(["Doridian", "foxbukkit-ci"])
  team_id  = github_team.ci.id

  username = each.key
  role     = "member"
}

resource "github_membership" "members" {
  for_each = local.members

  username = each.key
  role     = each.value
}
