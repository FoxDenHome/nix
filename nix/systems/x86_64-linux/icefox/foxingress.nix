{ config, ... }:
let
  mkV6Host = config.lib.system.mkV6Host;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    foxIngress = {
      enable = true;
      host = "foxingress";
      configFromGateway = "icefox";
    };
  };

  foxDen.hosts.hosts = {
    foxingress = mkV6Host {
      dns = {
        name = "icefox-foxingress";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:2/112"
        "10.99.12.2/24"
        "fd2c:f4cb:63be::a63:c02/120"
      ];
    };
  };
}
