{ lib, pkgs, ...} :
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  environment.systemPackages = with pkgs; [
    zfs
  ];
}
