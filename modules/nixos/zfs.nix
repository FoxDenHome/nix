{ lib, pkgs, ...} :
{
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [
    zfs
  ];

  boot.zfs.forceImportAll = true;

  environment.persistence."/nix/persist/system".files = [
    { file = "/etc/zfs/zpool.cache"; }
  ];
}
