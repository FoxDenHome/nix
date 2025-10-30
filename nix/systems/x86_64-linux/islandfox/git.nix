{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
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
      oAuth = {
        enable = true;
        clientId = "git";
        displayName = "Git";
      };
    };
  };

  foxDen.hosts.hosts = {
    git = mkVlanHost 2 {
      dns = {
        name = "git.foxden.network";
        dynDns = true;
      };
      webservice.enable = true;
      addresses = [
        "10.2.11.13/16"
        "fd2c:f4cb:63be:2::b0d/64"
      ];
    };
  };
}
