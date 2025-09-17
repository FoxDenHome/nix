{ lib,  ... }:
{
  system.stateVersion = "25.05";

  networking.hostName = "icefox";
  networking.hostId = "49434546";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # TODO: Most of this file
}
