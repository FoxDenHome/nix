{ ... } :
let
  mkWanRecs = (suffix: v4: v6: [
    {
      zone = "foxden.network";
      name = suffix;
      type = "A";
      value = v4;
      ttl = 300;
      dynDns = true;
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = suffix;
      type = "AAAA";
      value = v6;
      ttl = 300;
      dynDns = true;
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "v4-${suffix}";
      type = "A";
      value = v4;
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
      name = "ntp";
      type = "CNAME";
      ttl = 3600;
      value = "wan.foxden.network.";
      horizon = "external";
    }
    {
      zone = "foxden.network";
      name = "vpn";
      type = "A";
      ttl = 3600;
      value = "10.2.1.1";
      horizon = "internal";
    }
    {
      zone = "foxden.network";
      name = "v4-vpn";
      type = "A";
      ttl = 3600;
      value = "10.2.1.1";
      horizon = "internal";
    }
  ]
  ++ (mkWanRecs "wan" "10.2.0.1" "fd2c:f4cb:63be:2::1")
  ++ (mkWanRecs "router" "10.2.1.1" "fd2c:f4cb:63be:2::0101")
  ++ (mkWanRecs "router-backup" "10.2.1.2" "fd2c:f4cb:63be:2::0102");
}
