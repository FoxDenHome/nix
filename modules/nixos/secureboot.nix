{ lib, pkgs, config, ... }:
{
  security.audit.enable = true;
  security.apparmor.enable = true;

  boot = {
    initrd.systemd.enable = true;

    loader.systemd-boot.enable = lib.mkForce !config.boot.lanzaboote.enable;

    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = ["module.sig_enforce=1" "audit=1" "audit_backlog_limit=256" "lockdown=integrity"];

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  environment.systemPackages = with pkgs; [
    sbctl
  ];

  environment.persistence."/nix/persist/system".directories = [
    { directory = "/etc/secureboot"; mode = "u=rwx,g=rx,o="; }
  ];
}
