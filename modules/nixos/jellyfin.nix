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
  config.systemd.services.jellyfin.serviceConfig = nixpkgs.lib.mergeAttrs
                                                      {
                                                          ReadWritePaths = [
                                                            config.services.jellyfin.cacheDir
                                                            config.services.jellyfin.configDir
                                                          ];
                                                      }
                                                      svc.systemd.serviceConfig;

  environment.persistence."/nix/persist/jellyfin".directories = [
    { directory = config.services.jellyfin.cacheDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
    { directory = config.services.jellyfin.configDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
  ];
}
