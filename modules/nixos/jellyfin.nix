{ nixpkgs, config, ... }:
let
  services = import ../services.nix { inherit nixpkgs; };
  svc = services.make {
    inherit config;
    name = "jellyfin";
    opts.description = "Jellyfin media server";
  };
in
{
  config.services.jellyfin.enable = svc.enable;
  config.systemd.services.jellyfin.serviceConfig = svc.systemd.serviceConfig;
}
