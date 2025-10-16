locals {
  archived_repositores = {
    lua-resty-auto-ssl    = {},
    base-image            = {},
    FoxScreen             = {},
    LEGACY_foxCavesChrome = {},
    LEGACY_foxScreen      = {},
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
