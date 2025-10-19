{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    kanidm.server = {
      enable = true;
      tls = true;
      host = "auth";
    };
    oauth-jit-radius = {
      enable = true;
      host = "radius";
      tls = true;
      oAuth = {
        clientId = "radius";
      };
    };
  };

  foxDen.hosts.hosts = {
    auth = mkVlanHost 1 {
      dns = {
        name = "auth";
        zone = "foxden.network";
        dynDns = true;
      };
      webservice.enable = true;
      addresses = [
        "10.1.14.1/16"
        "fd2c:f4cb:63be:1::e01/64"
      ];
    };
    radius = mkVlanHost 1 {
      dns = {
        name = "radius.auth";
        zone = "foxden.network";
        dynDns = true;
      };
      webservice.enable = true;
      addresses = [
        "10.1.14.2/16"
        "fd2c:f4cb:63be:1::e02/64"
      ];
    };
  };
}
