# Mostly https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/headless.nix
{ ... }:
{
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."autovt@".enable = false;
  boot.kernelParams = [
    "panic=1"
    "boot.panic_on_fail"
    "vga=0x317"
    "nomodeset"
  ];
  systemd.enableEmergencyMode = false;
  boot.loader.grub.splashImage = null;
}