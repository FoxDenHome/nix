{ config, ... }:
let
  mkVlanHost = config.lib.system.mkVlanHost;
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
        name = "foxcaves";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "@";
          zone = "f0x.es";
          type = "ALIAS";
        }
        {
          name = "www";
          zone = "f0x.es";
        }
        {
          name = "@";
          zone = "foxcav.es";
          type = "ALIAS";
        }
        {
          name = "www";
          zone = "foxcav.es";
        }
      ];
      snirouter = {
        enable = true;
        httpPort = 81;
        httpsPort = 444;
      };
      addresses = [
        "10.3.10.1/16"
        "fd2c:f4cb:63be:3::a01/64"
      ];
    };
  };
}
