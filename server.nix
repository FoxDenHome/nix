{ lib, pkgs, ... }:
{
  boot = {
    initrd.systemd.enable = true;

    loader.systemd-boot.enable = lib.mkForce false;

    kernelPackages = pkgs.linuxPackages_latest;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  services.sshd.enable = true;

  networking.useDHCP = lib.mkDefault true;
}
