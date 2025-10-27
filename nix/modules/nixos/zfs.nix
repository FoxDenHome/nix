{ pkgs, lib, config, ... }:
{
  options.foxDen.zfs = {
    enable = lib.mkEnableOption "Enable ZFS support";
    sanoid = {
      enable = lib.mkEnableOption "Enable sanoid snapshots for ZFS datasets";
      datasets = with lib.types; lib.mkOption {
        type = attrsOf anything;
        default = {};
        description = "ZFS datasets to snapshot with sanoid";
      };
    };
    syncoid = {
      enable = lib.mkEnableOption "Enable syncoid replication for ZFS datasets";
      commands = with lib.types; lib.mkOption {
        type = attrsOf anything;
        default = {};
        description = "Syncoid commands";
      };
    };
  };

  config = lib.mkIf config.foxDen.zfs.enable {
    boot.zfs.devNodes = "/dev/disk/by-path";
    environment.persistence."/nix/persist/system".files = [
      { file = "/etc/zfs/zpool.cache"; }
    ];
    boot.supportedFilesystems = [ "zfs" ];
    environment.systemPackages = with pkgs; [
      zfs
      sanoid
    ];

    services.syncoid = {
      enable = config.foxDen.zfs.syncoid.enable;
      commonArgs = [
        # "--sshport=2222"
        "--compress=none"
        "--source-bwlimit=75m"
        "--no-privilege-elevation"
      ];
      commands = lib.attrsets.mapAttrs (_: cfg: {
        sendOptions = [ "Lec" ];
      } // cfg) config.foxDen.zfs.syncoid.commands;
    };

    services.sanoid = {
      enable = config.foxDen.zfs.sanoid.enable;
      templates.foxden = {
        interval = "hourly";
        hourly = 36;
        daily = 30;
        monthly = 3;
        yearly = 0;
        autosnap = true;
        autoprune = true;
      };
      datasets = lib.attrsets.mapAttrs (_: cfg: {
        useTemplate = ["foxden"];
      } // cfg) config.foxDen.zfs.sanoid.datasets;
    };
  };
}
