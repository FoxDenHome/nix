{ pkgs, lib, config, ... } :
{
  options.foxDen.zfs = {
    enable = lib.mkEnableOption "Enable ZFS support.";
    sanoid = {
      enable = lib.mkEnableOption "Enable sanoid snapshots for ZFS datasets.";
      datasets = with lib.types; lib.mkOption {
        type = attrsOf anything;
        default = {};
        description = "ZFS datasets to snapshot with sanoid.";
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

    services.sanoid = {
      enable = config.foxDen.zfs.sanoid.enable;
      templates.foxden = {
        interval = "hourly";
        retention = {
          hourly = 36;
          daily = 30;
          monthly = 3;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
      };
      datasets = lib.attrsets.mapAttrs (_: cfg: { useTemplate = "foxden"; } // cfg) config.foxDen.zfs.sanoid.datasets;
    };
  };
}
