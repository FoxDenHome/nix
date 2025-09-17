{
  nixosModules.zfs = { pkgs, ... } :
  {
    boot.supportedFilesystems = [ "zfs" ];
    environment.systemPackages = with pkgs; [
      zfs
    ];

    boot.zfs.devNodes = "/dev/disk/by-path";

    environment.persistence."/nix/persist/system".files = [
      { file = "/etc/zfs/zpool.cache"; }
    ];
  };
}
