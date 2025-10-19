{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    e621dumper = {
      enable = true;
      dataDir = "/mnt/zhdd/e621";
      host = "e621dumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "e621dumper";
        bypassInternal = true;
      };
    };
    fadumper = {
      enable = true;
      dataDir = "/mnt/zhdd/furaffinity";
      host = "fadumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "fadumper";
        bypassInternal = true;
      };
    };
  };

  foxDen.hosts.hosts = {
    e621dumper = mkVlanHost 2 {
      dns = {
        name = "e621";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.2.11.18/16"
        "fd2c:f4cb:63be:3::b12/64"
      ];
    };
    fadumper = mkVlanHost 3 {
      dns = {
        name = "furaffinity";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.2.11.19/16"
        "fd2c:f4cb:63be:3::b13/64"
      ];
    };
  };
}
