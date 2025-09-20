{ nixpkgs, pkgs, lib, config, ... }:
let
  services = import ../../services.nix { inherit nixpkgs; };
  mkJellyfinDir = (dir: {
    directory = dir;
    user = config.services.jellyfin.user;
    group = config.services.jellyfin.group;
    mode = "u=rwx,g=,o=";
  });
in
{
  options.foxDen.services.jellyfin = with nixpkgs.types; {
    enable = lib.mkEnableOption "Jellyfin media server";
    url = lib.mkOption {
      type = str;
    };
    tls = lib.mkEnableOption "TLS";
  };

  config = lib.mkIf config.foxDen.services.jellyfin.enable (lib.mkMerge [
    (services.make {
      inherit config pkgs;
      host = "jellyfin";
    }).config
    (services.makeHTTPProxy {
      inherit config pkgs;
      host = "jellyfin";
      target = "http://localhost:8096";
      tls = config.foxDen.services.jellyfin.tls;
    }).config
    {
      services.jellyfin.enable = true;
      services.jellyfin.group = "share";

      systemd.services.jellyfin.serviceConfig = {
        ReadWritePaths = [
          config.services.jellyfin.cacheDir
          config.services.jellyfin.configDir
          config.services.jellyfin.dataDir
          config.services.jellyfin.logDir
        ];
      };

      environment.persistence."/nix/persist/jellyfin".directories = [
        (mkJellyfinDir config.services.jellyfin.cacheDir)
        (mkJellyfinDir config.services.jellyfin.configDir)
        (mkJellyfinDir config.services.jellyfin.dataDir)
        (mkJellyfinDir config.services.jellyfin.logDir)
      ];
    }
  ]);
}
