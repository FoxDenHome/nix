locals {
  repositores = {
    nodered = {
      branch_protection = false
      visibility        = "private"
    }
    homeassistant = {
      branch_protection = false
      visibility        = "private"
    }
    NixieClockDori = {}
    PaperESP32     = {}
    LCDify         = {}
    terraform = {
      branch_protection = false
      visibility        = "private"
    }
    e621dumper = {}
    tapemgr    = {}
    docker = {
      branch_protection = false
      visibility        = "private"
    }
    docker-sriov-plugin = {}
    router = {
      branch_protection = false
      visibility        = "private"
    }
    CC1101Duino = {}
    ntpi        = {}
    islandfox = {
      branch_protection = false
      visibility        = "private"
    }
    bengalfox = {
      branch_protection = false
      visibility        = "private"
    }
    scripts = {}
    sshkeys = {
      branch_protection = false
      visibility        = "private"
    }
    shutdownd         = {}
    BlissLightControl = {}
    hassio-ecoflow = {
      description = "EcoFlow Portable Power Station Integration for Home Assistant"
    }
    icefox = {
      branch_protection = false
      visibility        = "private"
    }
    keepass-unlocker = {}
    diagrams = {
      branch_protection = false
      visibility        = "private"
    }
    initcpio-copy-efi2 = {}
    linuxptp = {
      description = "Linux PTP Project"
    }
    backupmgr = {}
  }

  members = {
    Doridian    = "admin",
    SimonSchick = "admin",
  }
}

module "repo" {
  for_each = local.repositores

  source = "../modules/repo"
  repository = merge({
    name         = each.key
    description  = ""
    homepage_url = ""

    visibility = "public"

    required_checks   = []
    branch_protection = true

    pages = null
  }, each.value)
}

resource "github_membership" "members" {
  for_each = local.members

  username = each.key
  role     = each.value
}
