{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    deluge = {
      enable = true;
      host = "deluge";
      enableHttp = false;
      downloadsDir = "/mnt/zssd/nas/torrent";
    };
    jellyfin = {
      enable = true;
      host = "jellyfin";
      mediaDir = "/mnt/zhdd/nas";
      tls = true;
    };
    kiwix = {
      enable = true;
      host = "kiwix";
      dataDir = "/mnt/zhdd/kiwix";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "kiwix-bengalfox";
        bypassInternal = true;
      };
    };
    nasweb = {
      host = "nas";
      enable = true;
      root = "/mnt/zhdd/nas";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "nas-bengalfox";
        bypassInternal = true;
      };
    };
    nzbget = {
      enable = true;
      host = "nzbget";
      enableHttp = false;
      downloadsDir = "/mnt/zssd/nas/usenet";
    };
    samba = {
      enable = true;
      host = "nas";
      sharePaths = [ "/mnt/zhdd/nas" "/mnt/zhdd/nashome" ];
    };
  };

  services.samba.settings = {
    homes = {
      "comment" = "Home Directories";
      "browseable" = "no";
      "guest ok" = "no";
      "writable" = "yes";
      "create mask" = "0600";
      "directory mask" = "0700";
      "path" = "/mnt/zhdd/nashome/%u";
      "follow symlinks" = "no";
      "wide links" = "no";
    };
    share = {
      "comment" = "NAS share";
      "browseable" = "yes";
      "guest ok" = "yes";
      "read only" = "yes";
      "write list" = "wizzy doridian";
      "printable" = "no";
      "create mask" = "0664";
      "force create mode" = "0664";
      "force group" = "share";
      "directory mask" = "2775";
      "force directory mode" = "2775";
      "path" = "/mnt/zhdd/nas";
      "follow symlinks" = "no";
      "wide links" = "no";
      "veto files" = "/.*/";
      "delete veto files" = "yes";
    };
  };

  foxDen.hosts.hosts = {
    deluge = (mkVlanHost 2 {
      dns = {
        name = "deluge";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.8/16"
        "fd2c:f4cb:63be:2::b08/64"
      ];
      routes = [
        { Destination = "10.0.0.0/8"; Gateway = "10.2.0.1"; }
        { Destination = "fd2c:f4cb:63be::/48"; Gateway = "fd2c:f4cb:63be:2::1"; }
      ];
      sysctls = {
        "net.ipv6.conf.INTERFACE.accept_ra_defrtr" = "0";
      };
    }) // {
      nameservers = [ "10.64.0.1" ];
    };
    jellyfin = mkVlanHost 2 {
      dns = {
        name = "jellyfin";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.2.11.3/16"
        "fd2c:f4cb:63be:2::b03/64"
      ];
    };
    kiwix = mkVlanHost 2 {
      dns = {
        name = "kiwix";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.2.11.6/16"
        "fd2c:f4cb:63be:2::b06/64"
      ];
    };
    nas = mkVlanHost 2 {
      dns = {
        name = "nas";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.2.11.1/16"
        "fd2c:f4cb:63be:2::b01/64"
      ];
    };
    nzbget = mkVlanHost 2 {
      dns = {
        name = "nzbget";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.9/16"
        "fd2c:f4cb:63be:2::b09/64"
      ];
    };
  };
}
