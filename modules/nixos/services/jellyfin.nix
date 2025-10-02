{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.jellyfin.user;
    group = config.services.jellyfin.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.jellyfin;
in
{
  options.foxDen.services.jellyfin = {
    mediaDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory to store Jellyfin media";
    };
  } // services.http.mkOptions { svcName = "jellyfin"; name = "Jellyfin media server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "jellyfin";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-jellyfin";
      target = "reverse_proxy http://127.0.0.1:8096";
    }).config
    {
      services.jellyfin.enable = true;
      services.jellyfin.group = "share";

      systemd.services.jellyfin.serviceConfig = {
        BindPaths = [
          config.services.jellyfin.cacheDir
          config.services.jellyfin.configDir
          config.services.jellyfin.dataDir
          config.services.jellyfin.logDir
        ];
        BindReadOnlyPaths = [
          "${svcConfig.mediaDir}:/data"
        ] ++ foxDenLib.services.mkEtcPaths [
          "fonts"
        ];
      };

      environment.persistence."/nix/persist/jellyfin" = {
        hideMounts = true;
        directories = [
          (mkDir config.services.jellyfin.cacheDir)
          (mkDir config.services.jellyfin.configDir)
          (mkDir config.services.jellyfin.dataDir)
          (mkDir config.services.jellyfin.logDir)
        ];
      };
    }
  ]);
}
