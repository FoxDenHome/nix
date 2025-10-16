{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    redfox = mkIntf {
      dns = {
        name = "redfox";
        zone = "foxden.network";
      };
      addresses = [
        "144.202.81.146"
        "2001:19f0:8001:f07:5400:4ff:feb1:d2e3"
      ];
    };
  };

  config.foxDen.dns.records = [
    {
      zone = "foxden.network";
      name = "v4-redfox";
      type = "A";
      ttl = 3600;
      value = "144.202.81.146";
      horizon = "external";
    }
  ];
}
