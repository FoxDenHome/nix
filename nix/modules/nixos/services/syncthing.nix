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
      name = "http-syncthing";
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-webdav@v0.0.0-20250805175825-7a5c90d8bf90" ];
        hash = "sha256-FOs4Y6UZWmUHDYWdKoqcU8k6hodISYS03BQkGx76OpU=";
      };
      rawConfig = { baseWebConfig, proxyConfigNoHost, ... }: ''
        server {
          server_name ${svcConfig.syncthingHost};
          ${baseWebConfig true}
          location / {
            proxy_pass http://127.0.0.1:8384;
            ${proxyConfigNoHost}
            proxy_set_header Host localhost;
          }
        }
        server {
          access_log /dev/stdout;

          server_name ${svcConfig.webdavHost};
          ${baseWebConfig false}

          auth_basic "Syncthing WebDAV";
          auth_basic_user_file ${if config.foxDen.sops.available then config.sops.secrets.http-syncthing.path else "/dev/null"};

          root /syncthing;
          location / {
            log_not_found off;
            autoindex on;
          }
          location = /dav  {
            return 301 /dav/;
          }
          location /dav {
            dav_methods PUT DELETE MKCOL COPY MOVE;
            create_full_put_path on;
            dav_access user:rw;
          }
        }
      '';
    }).config
    {
      services.syncthing = {
        enable = true;
        dataDir = svcConfig.dataDir;
      };

      sops.secrets.http-syncthing = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "syncthing";
        group = "syncthing";
      };

      systemd.services.http-syncthing = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "syncthing";
          Group = "syncthing";
          BindPaths = [
            "${svcConfig.dataDir}:/syncthing"
          ];
          BindReadOnlyPaths = config.lib.foxDen.sops.mkIfAvailable [
            config.sops.secrets.http-syncthing.path
          ];
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
