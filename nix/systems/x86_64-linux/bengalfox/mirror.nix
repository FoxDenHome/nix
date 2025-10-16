{ config, ... }:
let
  mkVlanHost = config.lib.system.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    aurbuild = {
      enable = true;
      host = "mirror";
    };
    mirror = {
      enable = true;
      host = "mirror";
      tls = true;
      dataDir = "/mnt/zhdd/mirror";
      archMirrorId = "archlinux.doridian.net";
      sources.archlinux = {
        rsyncUrl = "rsync://mirror.doridian.net/archlinux/";
        forceSync = true;
      };
      sources.cachyos = {
        rsyncUrl = "rsync://mirror.doridian.net/cachyos/";
        forceSync = true;
      };
    };
  };

  foxDen.hosts.hosts = {
    mirror = mkVlanHost 3 {
      dns = {
        name = "mirror";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "archlinux";
          zone = "foxden.network";
        }
        {
          name = "cachyos";
          zone = "foxden.network";
        }
      ];
      snirouter = {
        enable = true;
        httpPort = 81;
        httpsPort = 444;
      };
      addresses = [
        "10.3.10.11/16"
        "fd2c:f4cb:63be:3::a0b/64"
      ];
    };
  };
}
