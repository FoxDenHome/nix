{ lib,  ... }:
{
  system.stateVersion = "25.05";

  networking.hostName = "islandfox";
  networking.hostId = "494c4446";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # TODO: Most of this file
}
