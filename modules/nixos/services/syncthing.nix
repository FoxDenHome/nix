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
    syncthingHost = lib.mkOption {
      type = lib.types.str;
      description = "Host to run syncthing in (empty for host)";
    };
    webdavHost = lib.mkOption {
      type = lib.types.str;
      description = "Host to run webdav in (empty for host)";
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
      webdav = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-webdav@v0.0.0-20250805175825-7a5c90d8bf90" ];
        hash = lib.fakeHash;
      };
      rawConfig = ''
        ${svcConfig.syncthingHost} {
          reverse_proxy http://127.0.0.1:8384 {
            header_up Host localhost
          }
        }
        ${svcConfig.webdavHost} {
          root * /syncthing
          file_server {
            browse
            hide .stfolder
          }
          rewrite /dav /dav/
          webdav /dav/* {
            prefix /dav
          }
          basicauth {
            doridian {$WEBDAV_PASSWORD_DORIDIAN}
          }
        }
      '';
    }).config
    {
      services.syncthing = {
        enable = true;
        dataDir = svcConfig.dataDir;
      };

      sops.secrets.caddy-syncthing = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
      };

      systemd.services.caddy-syncthing = {
        serviceConfig = {
          EnvironmentFile = [ config.sops.secrets.caddy-syncthing.path ];
        };
      };

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
