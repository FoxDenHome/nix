{ nixpkgs, ... }:
let
  services = import ../services.nix { inherit nixpkgs; };
  svc = services.mkHostService {
    name = "jellyfin";
    opts.description = "Jellyfin media server";
  };
in
{
  imports = [svc.module];
}
