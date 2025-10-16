{ config, ... }:
let
  mkV6Host = config.lib.system.mkV6Host;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    xmpp = {
      enable = true;
      host = "xmpp";
      tls = true;
    };
  };

  foxDen.dns.records = [
    {
      zone = "foxden.network";
      name = "_xmpp-client._tcp";
      type = "SRV";
      ttl = 3600;
      port = 5222;
      horizon = "*";
      priority = 5;
      weight = 0;
      value = "xmpp.foxden.network";
    }
    {
      zone = "foxden.network";
      name = "_xmpps-client._tcp";
      type = "SRV";
      ttl = 3600;
      port = 5223;
      horizon = "*";
      priority = 5;
      weight = 0;
      value = "xmpp.foxden.network";
    }
    {
      zone = "foxden.network";
      name = "_xmpp-server._tcp";
      type = "SRV";
      ttl = 3600;
      port = 5269;
      horizon = "*";
      priority = 5;
      weight = 0;
      value = "xmpp.foxden.network";
    }
  ];

  foxDen.hosts.hosts = {
    xmpp = mkV6Host {
      dns = {
        name = "@";
        zone = "foxden.network";
      };
      cnames = [
        {
          name = "xmpp";
          zone = "foxden.network";
        }
        {
          name = "upload.xmpp";
          zone = "foxden.network";
        }
      ];
      snirouter.enable = true;
      addresses = [
        "2a01:4f9:2b:1a42::1:4/112"
        "10.99.12.4/24"
        "fd2c:f4cb:63be::a63:c04/120"
      ];
    };
  };
}
