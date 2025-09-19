{ nixpkgs, config, ... }:
let
  services = import ../services.nix { inherit nixpkgs; };
  svc = services.make {
    inherit config;
    name = "jellyfin";
  };
in
{
  config.services.jellyfin.enable = svc.enable;
  config.systemd.services.jellyfin.serviceConfig = nixpkgs.lib.mergeAttrs
                                                      {
                                                          ReadWritePaths = [
                                                            config.services.jellyfin.cacheDir
                                                            config.services.jellyfin.configDir
                                                            config.services.jellyfin.dataDir
                                                            config.services.jellyfin.logDir
                                                          ];
                                                      }
                                                      svc.systemd.serviceConfig;
  config.systemd.services.jellyfin.unitConfig = svc.systemd.unitConfig;

  config.environment.persistence."/nix/persist/jellyfin".directories = [
    { directory = config.services.jellyfin.cacheDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
    { directory = config.services.jellyfin.configDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
    { directory = config.services.jellyfin.dataDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
    { directory = config.services.jellyfin.logDir; user = "jellyfin"; group = "jellyfin"; mode = "u=rwx,g=,o="; }
  ];
}
