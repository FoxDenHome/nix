{ lib, pkgs, ... }:
{
  boot = {
    initrd.systemd.enable = true;

    loader.systemd-boot.enable = lib.mkForce false;

    kernelPackages = pkgs.linuxPackages_latest;

    security.audit.enable = true;
    kernelParams = ["module.sig_enforce=1" "lsm=landlock,lockdown,yama,integrity,apparmor,bpf" "audit=1" "audit_backlog_limit=256" "lockdown=integrity"];

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
}
