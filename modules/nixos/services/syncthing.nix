{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.syncthing;

  defaultDataDir = "/var/lib/syncthing";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);
in
{
  options.foxDen.services.syncthing = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store syncthing data";
    };
  } // (services.http.mkOptions { svcName = "syncthing"; name = "Syncthing server"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "syncthing";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-syncthing";
      target = "reverse_proxy http://127.0.0.1:8384";
    }).config
    {
      services.syncthing.dataDir = svcConfig.dataDir;

      systemd.services.syncthing = {
        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          StateDirectory = ifDefaultData "syncthing";
        };
      };

      environment.persistence."/nix/persist/syncthing" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "syncthing"; group = "syncthing"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
