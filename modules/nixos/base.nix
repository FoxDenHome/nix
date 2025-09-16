{ lib, pkgs, ... }:
{
  services.sshd.enable = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    htop
    wget
    curl
  ];
}
