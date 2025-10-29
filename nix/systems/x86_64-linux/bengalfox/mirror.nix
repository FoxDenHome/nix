{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
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
    mirror = mkVlanHost 2 {
      dns = {
        name = "mirror.foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "archlinux.foxden.network";
        }
        {
          name = "cachyos.foxden.network";
        }
      ];
      webservice = {
        enable = true;
        httpPort = 81;
        httpsPort = 444;
      };
      firewall.ingressAcceptRules = [
        {
          protocol = "tcp";
          port = 80;
        }
        {
          protocol = "tcp";
          port = 443;
        }
        {
          protocol = "udp";
          port = 443;
        }
      ];
      addresses = [
        "10.2.11.17/16"
        "fd2c:f4cb:63be:3::b11/64"
      ];
    };
  };
}
