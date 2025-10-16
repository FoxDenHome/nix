{ config, ... }:
let
  mkV6Host = config.lib.foxDenSys.mkV6Host;
  mkMinHost = config.lib.foxDenSys.mkMinHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    wireguard."wg-deluge" = {
      host = "deluge"; # lawful dove
      interface = {
        ips = [ "10.73.218.165/32" "fc00:bbbb:bbbb:bb01::a:daa4/128" ];
        peers = [
          {
            allowedIPs = [ "0.0.0.0/0" "::/0" "10.64.0.1/32" ];
            endpoint = "193.138.7.157:51820";
            persistentKeepalive = 25;
            publicKey = "xeHVhXxyyFqUEE+nsu5Tzd/t9en+++4fVFcSFngpcAU=";
          }
        ];
      };
    };
    deluge = {
      enable = true;
      host = "deluge";
      enableHttp = false;
      downloadsDir = "/mnt/ztank/local/torrent";
    };
    kiwix = {
      enable = true;
      host = "kiwix";
      dataDir = "/mnt/zhdd/kiwix";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "kiwix-icefox";
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
        clientId = "nas-icefox";
        bypassInternal = true;
      };
    };
    nzbget = {
      enable = true;
      host = "nzbget";
      enableHttp = false;
      downloadsDir = "/mnt/ztank/local/usenet";
    };
    jellyfin = {
      host = "jellyfin";
      enable = true;
      mediaDir = "/mnt/zhdd/nas";
      tls = true;
    };
  };

  foxDen.hosts.hosts = {
    nas = mkV6Host {
      dns = {
        name = "nas-offsite";
        zone = "foxden.network";
      };
      snirouter.enable = true;
      addresses = [
        "2a01:4f9:2b:1a42::1:5/112"
        "10.99.12.5/24"
        "fd2c:f4cb:63be::a63:c05/120"
      ];
    };
    nzbget = mkV6Host {
      dns = {
        name = "nzbget-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:8/112"
        "10.99.12.8/24"
        "fd2c:f4cb:63be::a63:c08/120"
      ];
    };
    jellyfin = mkV6Host {
      dns = {
        name = "jellyfin-offsite";
        zone = "foxden.network";
      };
      snirouter.enable = true;
      addresses = [
        "2a01:4f9:2b:1a42::1:9/112"
        "10.99.12.9/24"
        "fd2c:f4cb:63be::a63:c09/120"
      ];
    };
    kiwix = mkV6Host {
      dns = {
        name = "kiwix-offsite";
        zone = "foxden.network";
      };
      snirouter.enable = true;
      addresses = [
        "2a01:4f9:2b:1a42::1:a/112"
        "10.99.12.10/24"
        "fd2c:f4cb:63be::a63:c0a/120"
      ];
    };
    deluge = let
      host = mkMinHost {
        dns = {
          name = "deluge-offsite";
          zone = "foxden.network";
        };
        addresses = [
          "10.99.12.11/24"
          "fd2c:f4cb:63be::a63:c0b/120"
        ];
      };
    in {
      nameservers = [ "10.64.0.1" ];
      interfaces.foxden = host.interfaces.foxden;
    };
  };
}
