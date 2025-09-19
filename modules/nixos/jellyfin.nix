{ nixpkgs, lib, config, ... }:
let
  services = import ../services.nix { inherit nixpkgs; };
  svc = services.make {
    inherit config;
    name = "jellyfin";
  };

  mkJellyfinDir = (dir: {
    directory = dir;
    user = config.services.jellyfin.user;
    group = config.services.jellyfin.group;
    mode = "u=rwx,g=,o=";
  });
in
{
  config = lib.mkIf svc.enable {
    services.jellyfin.enable = true;
    services.jellyfin.group = "share";

    systemd.services.jellyfin.serviceConfig =
      nixpkgs.lib.mergeAttrs
        {
            ReadWritePaths = [
              config.services.jellyfin.cacheDir
              config.services.jellyfin.configDir
              config.services.jellyfin.dataDir
              config.services.jellyfin.logDir
            ];
        }
        svc.systemd.serviceConfig;

    systemd.services.jellyfin.unitConfig = svc.systemd.unitConfig;

    environment.persistence."/nix/persist/jellyfin".directories = [
      (mkJellyfinDir config.services.jellyfin.cacheDir)
      (mkJellyfinDir config.services.jellyfin.configDir)
      (mkJellyfinDir config.services.jellyfin.dataDir)
      (mkJellyfinDir config.services.jellyfin.logDir)
    ];
  };
}
