locals {
  archived_repositores = {
    HAMqttDevice       = {}
    "3dprinter-config" = {}
    desk-control       = {}
    redfox             = {}
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
