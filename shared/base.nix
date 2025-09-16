{ lib, ... }:
{
  services.sshd.enable = true;
  networking.useDHCP = lib.mkDefault true;
}
