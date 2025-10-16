{ config, ... }:
let
  mkVlanHost = config.lib.system.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    syncthing = {
      enable = true;
      host = "syncthing";
      tls = true;
      syncthingHost = "syncthing.foxden.network";
      webdavHost = "webdav.syncthing.foxden.network";
    };
  };

  foxDen.hosts.hosts = {
    syncthing = mkVlanHost 2 {
      dns = {
        name = "syncthing";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "webdav.syncthing";
          zone = "foxden.network";
        }
      ];
      addresses = [
        "10.2.11.2/16"
        "fd2c:f4cb:63be:2::b02/64"
      ];
    };
  };
}
