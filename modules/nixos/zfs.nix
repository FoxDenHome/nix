{ ... } :
{
  boot.zfs.devNodes = "/dev/disk/by-path";

  environment.persistence."/nix/persist/system".files = [
    { file = "/etc/zfs/zpool.cache"; }
  ];
}
