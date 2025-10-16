locals {
  archived_repositores = {
    HAMqttDevice       = {}
    "3dprinter-config" = {}
    desk-control       = {}
    redfox             = {}

    terraform = {
      visibility = "private"
    }
    docker = {
      visibility = "private"
    }
    docker-sriov-plugin = {}
    router = {
      visibility = "private"
    }
    islandfox = {
      visibility = "private"
    }
    bengalfox = {
      visibility = "private"
    }
    scripts = {}
    sshkeys = {
      visibility = "private"
    }
    icefox = {
      visibility = "private"
    }

    diagrams = {
      visibility = "private"
    }
    linuxptp = {
      description = "Linux PTP Project"
    }
    initcpio-copy-efi2 = {}
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
