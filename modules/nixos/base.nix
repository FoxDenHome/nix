{ lib, impermanence, pkgs, foxDenLib, config, ... }:
{
  imports = [
    impermanence.nixosModules.impermanence
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.sshd.enable = true;
  networking.useNetworkd = true;

  boot.supportedFilesystems = [ "vfat" "xfs" "ext4" ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    age
    bridge-utils
    cryptsetup
    curl
    e2fsprogs
    gptfdisk
    mdadm
    ncdu
    openssl
    screen
    ssh-to-age
    tmux
    unixtools.netstat
    wget
    xfsprogs
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.htop.enable = true;
  programs.tcpdump.enable = true;

  nix.settings.allowed-users = [ "root" "@wheel" ];

  security.sudo.enable = false;
  security.polkit.enable = true;
  users.users.root.shell = "${pkgs.fish}/bin/fish";

  users.groups.share.gid = 1001;

  networking.hostId = lib.mkDefault (foxDenLib.util.mkHash8 config.networking.hostName);
  networking.wireguard.useNetworkd = false;
  networking.firewall.logRefusedConnections = false;

  services.timesyncd.servers = lib.mkDefault [ "ntp.foxden.network" ];

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
    ] ++ lib.lists.flatten (lib.lists.forEach config.services.openssh.hostKeys ({path, ...}: [
      "${path}"
      "${path}.pub"
    ]));
  };
}
