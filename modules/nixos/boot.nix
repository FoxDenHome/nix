{
  module = { lib, pkgs, config, ... }:
  {
    security.audit.enable = false;
    security.apparmor.enable = true;

    boot = {
      initrd.systemd.enable = true;

      kernelPackages = pkgs.linuxPackages_latest;
      kernelParams = ["module.sig_enforce=1" "lockdown=integrity"];
      # "audit=1" "audit_backlog_limit=256"

      loader.systemd-boot.enable = lib.mkForce (! config.boot.lanzaboote.enable);
      lanzaboote.pkiBundle = "/etc/secureboot";
    };

    environment.systemPackages = with pkgs; [
      sbctl
    ];

    environment.persistence."/nix/persist/system".directories = [
      { directory = "/etc/secureboot"; mode = "u=rwx,g=rx,o="; }
    ];
  };
}
