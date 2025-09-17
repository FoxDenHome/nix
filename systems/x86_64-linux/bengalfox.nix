{ lib,  ... }:
{
  system.stateVersion = "25.05";

  networking.hostName = "bengalfox";
  networking.hostId = "42474c46";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # TODO: Most of this file
}
