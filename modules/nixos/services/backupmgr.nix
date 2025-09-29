{ foxDenLib, backupmgr, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = "root";
    group = "root";
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.backupmgr;

  backupmgrPkg = backupmgr.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.backupmgr.enable = lib.mkEnableOption "backupmgr";

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.restic
        backupmgrPkg
      ];

      systemd.services.backupmgr-backup = {
        unitConfig = {
          Conflicts = [ "backupmgr-prune.service" ];
        };
        serviceConfig = {
          Type = "simple";
          Restart = "no";
          ExecStart = [ "${backupmgrPkg}/bin/backupmgr --mode=backup" ];
        };
      };

      systemd.timers.backupmgr-backup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "30m";
          OnUnitActiveSec = "1h";
        };
      };

      systemd.services.backupmgr-prune = {
        unitConfig = {
          Conflicts = [ "backupmgr-backup.service" ];
        };
        serviceConfig = {
          Type = "simple";
          Restart = "no";
          ExecStart = [ "${backupmgrPkg}/bin/backupmgr --mode=prune" ];
        };
      };

      systemd.timers.backupmgr-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "6h";
          OnUnitActiveSec = "7d";
        };
      };

      sops.secrets.backupmgr = config.lib.foxDen.sops.mkIfAvailable {};

      environment.etc."backupmgr/config.json" = config.lib.foxDen.sops.mkIfAvailable {
        source = config.sops.secrets.backupmgr.path;
        user = "root";
        group = "root";
        mode = "0400";
      };
    }
  ]);
}
