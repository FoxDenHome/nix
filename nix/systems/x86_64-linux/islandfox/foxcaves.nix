{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    foxcaves = {
      enable = true;
      host = "foxcaves";
    };
  };

  foxDen.hosts.hosts = {
    foxcaves = mkVlanHost 3 {
      dns = {
        name = "foxcaves.foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "f0x.es";
          type = "ALIAS";
        }
        {
          name = "www.f0x.es";
        }
        {
          name = "foxcav.es";
          type = "ALIAS";
        }
        {
          name = "www.foxcav.es";
        }
      ];
      webservice.enable = true;
      addresses = [
        "10.3.10.1/16"
        "fd2c:f4cb:63be:3::a01/64"
      ];
    };
  };
}
