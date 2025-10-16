locals {
  archived_repositores = {
    Deployer = {},
    LuaJIT   = {},
    Runner   = {},
    Web      = {},
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
