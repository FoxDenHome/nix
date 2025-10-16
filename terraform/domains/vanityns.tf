locals {
  vanity_nameservers = {
    "doridian.de" = {
      list = ["ns1.doridian.de", "ns2.doridian.de", "ns3.doridian.de", "ns4.doridian.de"]
      name = "doridian.de"
    }
    "doridian.net" = {
      list = ["ns1.doridian.net", "ns2.doridian.net", "ns3.doridian.net", "ns4.doridian.net"]
      name = "doridian.net"
    }
    "foxden.network" = {
      list = ["ns1.foxden.network", "ns2.foxden.network", "ns3.foxden.network", "ns4.foxden.network"]
      name = "foxden.network"
    }
  }
}
