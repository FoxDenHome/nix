locals {
  domains = {
    "doridian.de" = {
      vanity_nameserver = "doridian.de",
      registrar         = "inwx",
    },
    "doridian.net" = {},
    "dori.fyi" = {
      registrar = "inwx",
    },
    "f0x.es"              = {},
    "foxcav.es"           = {},
    "darksignsonline.com" = {},
    "foxden.network" = {
      vanity_nameserver = "foxden.network",
    },
    "spaceage.mp" = {
      registrar = "getmp",
    },

    // RIPE /40
    "0.f.4.4.d.7.e.0.a.2.ip6.arpa" = {
      registrar = "ripe",
    },
    // RIPE /44
    "c.1.2.2.0.f.8.e.0.a.2.ip6.arpa" = {
      registrar = "ripe",
    },
  }

  default_vanity_nameserver = "doridian.net"

  records_json = jsondecode(data.external.nix_records_json.result.json)
}

data "external" "nix_records_json" {
  program = ["${path.module}/nix.sh"]
  query   = {}
}

module "domain" {
  source   = "../modules/domain"
  for_each = local.domains

  domain            = each.key
  fastmail          = !endswith(each.key, ".arpa")
  ses               = !endswith(each.key, ".arpa")
  root_aname        = null
  add_www_cname     = false
  vanity_nameserver = local.vanity_nameservers[try(each.value.vanity_nameserver, local.default_vanity_nameserver)]
  registrar         = try(each.value.registrar, "aws")
}

module "domain_jsonrecords" {
  source   = "./jsonrecords"
  for_each = local.domains

  domain  = each.key
  zone    = module.domain[each.key].zone
  records = try(local.records_json[each.key], [])
}

output "dynamic_urls" {
  value = flatten([for domain in module.domain_jsonrecords : domain.dynamic_urls])
}
