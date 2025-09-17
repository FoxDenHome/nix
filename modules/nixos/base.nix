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
    e2fsprogs
    xfsprogs
    fish
    zsh
  ];

  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = "$y$j9T$IiDZbOYNQ3/pi9/K2QdUm0$GizBNTJUmYCp3OTixpF6kkmFy6XMwszNIxmbOcaEtyA";
  };

  environment.persistence."/nix/persist/system" = {
    hideMounts = true;

    directories = [
      "/home"
      { directory = "/root"; mode = "u=rwx,g=,o="; }
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
    ];

    files = [
      "/etc/machine-id"
      { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ] ++ lib.lists.flatten (lib.lists.forEach config.services.openssh.hostKeys ({path, ...}: [
      "${path}"
      "${path}.pub"
    ]));
  };
}
