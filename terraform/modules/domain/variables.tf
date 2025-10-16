variable "domain" {
  type = string
}

variable "fastmail" {
  type = bool
}

variable "root_aname" {
  type    = string
  default = null
}

variable "root_aname_ttl" {
  type    = number
  default = 300
}

variable "add_www_cname" {
  type = bool
}

variable "ses" {
  type = bool
}

variable "vanity_nameserver" {
  type = object({
    name = string
    list = list(string)
  })
  default = null
}

variable "registrar" {
  type    = string
  default = ""
}
