{ nixpkgs, config, ... }:
let
  services = import ../services.nix { inherit nixpkgs; };
  svc = services.mkHostService {
    inherit config;
    name = "jellyfin";
    opts.description = "Jellyfin media server";
  };
in
{
  config.systemd.slices.jellyfin = svc.slice;
}
