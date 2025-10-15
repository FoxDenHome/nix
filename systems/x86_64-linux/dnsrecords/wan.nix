{ ... } :
let
  mkWanRecs = (suffix: [
    {
      zone = "foxden.network";
      name = suffix;
      type = "A";
      value = "127.0.0.1";
      ttl = 300;
      dynDns = true;
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = suffix;
      type = "AAAA";
      value = "::1";
      ttl = 300;
      dynDns = true;
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "v4-${suffix}";
      type = "A";
      value = "127.0.0.1";
      ttl = 300;
      dynDns = true;
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "v4-${suffix}";
      type = "CNAME";
      value = "${suffix}.foxden.network.";
      ttl = 300;
      horizon = "internal";
    }
  ]);
in
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
      name = "vpn";
      type = "CNAME";
      ttl = 3600;
      value = "router.foxden.network.";
      horizon = "internal";
    }
    {
      zone = "foxden.network";
      name = "v4-vpn";
      type = "CNAME";
      ttl = 3600;
      value = "router.foxden.network.";
      horizon = "internal";
    }
    {
      zone = "foxden.network";
      name = "ntp";
      type = "CNAME";
      ttl = 3600;
      value = "wan.foxden.network.";
      horizon = "external";
    }
  ]
  ++ (mkWanRecs "wan")
  ++ (mkWanRecs "router")
  ++ (mkWanRecs "router-backup");
}
