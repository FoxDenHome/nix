{ lib, pkgs, config, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.sshd.enable = true;

  boot.supportedFilesystems = [ "vfat" "xfs" "ext4" ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    curl
    e2fsprogs
    openssl
    wget
    xfsprogs
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.htop.enable = true;
  programs.tcpdump.enable = true;

  users.users.root = {
    initialHashedPassword = "$y$j9T$IiDZbOYNQ3/pi9/K2QdUm0$GizBNTJUmYCp3OTixpF6kkmFy6XMwszNIxmbOcaEtyA";
    shell = "${pkgs.fish}/bin/fish";
  };

  users.groups.share = {
    gid = 1001;
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
