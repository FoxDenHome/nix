{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    doridian-website = {
      enable = true;
      host = "doridian-website";
      tls = true;
    };
  };

  foxDen.hosts.hosts = {
    doridian-website = mkVlanHost 2 {
      dns = {
        name = "website.foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "doridian.net";
          type = "ALIAS";
        }
        {
          name = "www.doridian.net";
        }
        {
          name = "doridian.de";
          type = "ALIAS";
        }
        {
          name = "www.doridian.de";
        }
      ];
      webservice.enable = true;
      addresses = [
        "10.2.11.15/16"
        "fd2c:f4cb:63be:3::b0f/64"
      ];
    };
  };
}
