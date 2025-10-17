{ ... } :
{
  foxDen.hosts.gateway = "redfox";
  foxDen.hosts.index = 3;

  foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    redfox = mkIntf {
      dns = {
        name = "redfox";
        zone = "foxden.network";
      };
      cnames = [
        {
          name = "redfox";
          zone = "doridian.net";
        }
      ];
      addresses = [
        "10.99.10.1"
        "fd2c:f4cb:63be::a63:a01"
        "144.202.81.146"
        "2001:19f0:8001:f07:5400:4ff:feb1:d2e3"
      ];
    };
  };

  foxDen.dns.records = [
    {
      zone = "doridian.net";
      name = "v4-redfox";
      type = "A";
      ttl = 3600;
      value = "144.202.81.146";
      horizon = "external";
    }
    {
      zone = "doridian.net";
      name = "v4-redfox";
      type = "CNAME";
      ttl = 3600;
      value = "redfox.foxden.network.";
      horizon = "internal";
    }
  ];
}
