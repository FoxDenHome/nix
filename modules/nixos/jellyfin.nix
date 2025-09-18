{ nixpkgs, ... }:
let
  service = import ../service.nix { inherit nixpkgs; };
in
{
  imports = [
    (service.mkHostService {
      name = "jellyfin";
      opts.description = "Jellyfin media server";
    })
  ];
}
