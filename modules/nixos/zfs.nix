{ lib, pkgs, ...} :
{
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [
    zfs
  ];

  boot.zfs.forceImportRoot = false;

  environment.persistence."/nix/persist/system".files = [
    { file = "/etc/zfs/zpool.cache"; }
  ];
}
