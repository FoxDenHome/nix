{ lib, pkgs, ...} :
{
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [
    zfs
  ];

  boot.zfs.forceImportRoot = false;
}
