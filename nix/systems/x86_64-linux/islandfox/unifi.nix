{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    unifi = {
      enable = true;
      host = "unifi";
    };
  };

  foxDen.hosts.hosts = {
    unifi = mkVlanHost 1 {
      dns = {
        name = "unifi";
        zone = "foxden.network";
      };
      firewall.openPorts = [
        {
          source = "10.2.0.0/16";
        }
        {
          source = "fd2c:f4cb:63be:2::/16";
        }
      ];
      addresses = [
        "10.1.10.1/16"
        "fd2c:f4cb:63be:1::a01/64"
      ];
    };
  };
}
