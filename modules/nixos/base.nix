{ lib, pkgs, config, ... }:
{
  services.sshd.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    htop
    wget
    curl
    openssl
    tcpdump
  ];

  environment.persistence."/nix/persist/system" = {
    hideMounts = true;

    directories = [
      "/home"
      "/root"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
    ] ++ lib.lists.flatten (lib.lists.forEach config.services.openssh.hostKeys ({path, ...}: [
      "/etc/ssh/${path}"
      "/etc/ssh/${path}.pub"
    ]));

    files = [
      "/etc/machine-id"
      { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
  };
}
