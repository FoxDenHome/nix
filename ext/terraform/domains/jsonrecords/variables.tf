variable "domain" {
  type = string
}

variable "zone" {
  type = string
}

variable "records" {
  type = list(object({
    dynDns   = optional(bool, false)
    horizon  = string
    name     = string
    ttl      = number
    type     = string
    value    = string
    zone     = string
    priority = optional(number)
    port     = optional(number)
    weight   = optional(number)
  }))
}
