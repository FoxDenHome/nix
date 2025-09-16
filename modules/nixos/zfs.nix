{ lib, pkgs, ...} :
{
  environment.systemPackages = with pkgs; [
    zfs
  ];

  boot.kernelModules = [
    "zfs"
    "spl"
  ];
}
