locals {
  domains = {
    "candy-girl.net" = {
      registrar = "aws",
    },
    "zoofaeth.de" = {
      registrar = "inwx",
    },
  }
}

module "records" {
  for_each = local.domains
  source   = "./records"

  zone   = module.domain[each.key].zone
  domain = each.key
}

module "domain" {
  source = "../modules/domain"

  for_each = local.domains

  domain = each.key

  root_aname     = "arcticfox.doridian.net"
  root_aname_ttl = 3600
  fastmail       = false
  ses            = true
  add_www_cname  = true

  registrar = each.value.registrar
}
