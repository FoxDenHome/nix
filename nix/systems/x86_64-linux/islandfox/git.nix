{ config, ... }:
let
  mkVlanHost = config.lib.system.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    gitbackup = {
      enable = true;
      host = "";
    };
    forgejo = {
      enable = true;
      host = "git";
      tls = true;
    };
  };

  foxDen.hosts.hosts = {
    git = mkVlanHost 3 {
      dns = {
        name = "git";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.3.10.2/16"
        "fd2c:f4cb:63be:3::a02/64"
      ];
    };
  };
}
