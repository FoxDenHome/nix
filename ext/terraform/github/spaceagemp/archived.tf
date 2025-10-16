locals {
  archived_repositores = {
    SpaceAgeCentral = {},
    SpaceAge_Old_Archive = {
      visibility = "private",
    },
    ansible = {
      visibility        = "private"
      branch_protection = false
    }
  }
}

module "archived_repo" {
  source = "../modules/repo/archived"

  for_each = local.archived_repositores

  repository = merge({
    name = each.key

    visibility = "public"
  }, each.value)
}
