{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = "prometheus";
    group = "prometheus";
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.prometheus;
in
{
  options.foxDen.services.prometheus = {

  } // services.mkOptions { svcName = "prometheus"; name = "Prometheus monitoring server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "mktxp";
      inherit svcConfig pkgs config;
    }).config
    {
      sops.secrets.mktxp = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "mktxp";
        group = "mktxp";
      };

      users.users.mktxp = {
        isSystemUser = true;
        group = "mktxp";
      };
      users.groups.mktxp = {};

      systemd.services.mktxp = {
        serviceConfig = {
          ExecStartPre = [
            "${pkgs.coreutils}/bin/touch /tmp/mktxp.conf"
            "${pkgs.coreutils}/bin/chmod 600 /tmp/mktxp.conf"
            "${pkgs.coreutils}/bin/sh -c 'cat ${./mktxp.conf} | sed \"s/__MTIK_USERNAME__/$MTIK_USERNAME/g\" | sed \"s/__MTIK_PASSWORD__/$MTIK_PASSWORD/g\" > /tmp/mktxp.conf'"
          ];

          ExecStart = [
            "${pkgs.mktxp}/bin/mktxp export"
          ];

          Type = "simple";

          User = "mktxp";
          Group = "mktxp";

          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.mktxp.path;
        };

        wantedBy = [ "multi-user.target" ];
      };
    }
  ]);
}
