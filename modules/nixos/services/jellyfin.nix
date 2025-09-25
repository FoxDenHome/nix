{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkJellyfinDir = (dir: {
    directory = dir;
    user = config.services.jellyfin.user;
    group = config.services.jellyfin.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.jellyfin;
in
{
  options.foxDen.services.jellyfin = services.http.mkOptions { svcName = "jellyfin"; name = "Jellyfin media server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      target = "reverse_proxy http://localhost:8096";
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

        TemporaryPaths = [
          "/var/cache/fontconfig"
        ];
      };

      environment.persistence."/nix/persist/jellyfin" = {
        hideMounts = true;
        directories = [
          (mkJellyfinDir config.services.jellyfin.cacheDir)
          (mkJellyfinDir config.services.jellyfin.configDir)
          (mkJellyfinDir config.services.jellyfin.dataDir)
          (mkJellyfinDir config.services.jellyfin.logDir)
        ];
      };
    }
  ]);
}
