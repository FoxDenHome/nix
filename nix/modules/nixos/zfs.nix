{ pkgs, ... } :
{
  boot.supportedFilesystems = [ "zfs" ];

  boot.zfs.devNodes = "/dev/disk/by-path";

  environment.persistence."/nix/persist/system".files = [
    { file = "/etc/zfs/zpool.cache"; }
  ];

  environment.systemPackages = with pkgs; [
    zfs
  ];
}
