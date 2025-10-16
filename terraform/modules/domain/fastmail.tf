resource "cloudns_dns_record" "smtp" {
  count = var.fastmail ? 2 : 0
  zone  = cloudns_dns_zone.domain.id

  name     = ""
  type     = "MX"
  ttl      = 3600
  value    = "in${count.index + 1}-smtp.messagingengine.com"
  priority = 10 * (count.index + 1)
}

resource "cloudns_dns_record" "dkim" {
  count = var.fastmail ? 3 : 0
  zone  = cloudns_dns_zone.domain.id

  name  = "fm${count.index + 1}._domainkey"
  type  = "CNAME"
  ttl   = 3600
  value = "fm${count.index + 1}.${var.domain}.dkim.fmhosted.com"
}
