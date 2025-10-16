variable "repository" {
  type = object({
    name         = string
    description  = string
    homepage_url = string

    visibility = string

    branch_protection = bool
    required_checks   = set(string)

    default_branch = optional(string)

    pages = object({
      cname = string
    })
  })
}
