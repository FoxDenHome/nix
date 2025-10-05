{ pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.backupmgr;
in
{
  options.foxDen.services.backupmgr.enable = lib.mkEnableOption "backupmgr";

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.restic
        pkgs.backupmgr
      ];

      systemd.services.backupmgr-backup = {
        path = [
          pkgs.restic
        ];
        conflicts = [ "backupmgr-prune.service" ];
        serviceConfig = {
          Type = "simple";
          Restart = "no";
          ExecStart = [ "${pkgs.backupmgr}/bin/backupmgr --mode=backup" ];
        };
      };

      systemd.timers.backupmgr-backup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          RandomizedDelaySec = "30m";
        };
      };

      systemd.services.backupmgr-prune = {
        path = [
          pkgs.restic
        ];
        conflicts = [ "backupmgr-backup.service" ];
        serviceConfig = {
          Type = "simple";
          Restart = "no";
          ExecStart = [ "${pkgs.backupmgr}/bin/backupmgr --mode=prune" ];
        };
      };

      systemd.timers.backupmgr-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          RandomizedDelaySec = "12h";
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
