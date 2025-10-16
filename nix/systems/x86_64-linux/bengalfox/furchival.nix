{ config, ... }:
let
  mkVlanHost = config.lib.system.mkVlanHost;
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
    e621dumper = mkVlanHost 3 {
      dns = {
        name = "e621";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      addresses = [
        "10.3.10.12/16"
        "fd2c:f4cb:63be:3::a0c/64"
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
        "10.3.10.13/16"
        "fd2c:f4cb:63be:3::a0d/64"
      ];
    };
  };
}
