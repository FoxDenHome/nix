{ ... } :
{
  config.foxDen.dns.records = [
    {
      zone = "foxden.network";
      name = "vpn";
      type = "CNAME";
      ttl = 3600;
      value = "v4-wan.foxden.network.";
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "v4-vpn";
      type = "CNAME";
      ttl = 3600;
      value = "v4-wan.foxden.network.";
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "ntp";
      type = "CNAME";
      ttl = 3600;
      value = "wan.foxden.network.";
      horizon = "external";
    }
  ];
}
