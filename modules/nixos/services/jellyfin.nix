{ nixpkgs, lib, config, ... }:
let
  services = import ../../services.nix { inherit nixpkgs; };
  svc = services.make {
    inherit config;
    name = config.foxDen.services.jellyfin.host;
  };
  svcHttp = services.makeHTTPProxy {
    inherit config;
    name = config.foxDen.services.jellyfin.host;
    target = "http://localhost:8096";
  };

  mkJellyfinDir = (dir: {
    directory = dir;
    user = config.services.jellyfin.user;
    group = config.services.jellyfin.group;
    mode = "u=rwx,g=,o=";
  });
in
{
  options.foxDen.services.jellyfin = with lib.types; { 
    host = lib.mkOption {
      type = str;
      default = "jellyfin";
    };
    enable = lib.mkEnableOption "Jellyfin media server";
  };

  config = lib.mkIf config.foxDen.services.jellyfin.enable {
    services.jellyfin.enable = true;
    services.jellyfin.group = "share";

    systemd.services.jellyfin.serviceConfig =
      lib.mergeAttrs
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
