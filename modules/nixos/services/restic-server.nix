{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.restic-server;

  defaultDataDir = "/var/lib/restic";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  restServerConfig = (services.make {
    name = "restic-rest-server";
    inherit svcConfig pkgs config;
  }).config;
  restServerSvcConfig = restServerConfig.systemd.services."restic-rest-server";
in
{
  options.foxDen.services.restic-server = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store restic-server data";
    };
  } // (services.http.mkOptions { svcName = "restic-server"; name = "Restic Backup Server"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    restServerConfig
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-restic-rest-server";
      target = "reverse_proxy http://127.0.0.1:8000";
    }).config
    {
      services.restic.server = {
        enable = true;
        dataDir = svcConfig.dataDir;
        privateRepos = true;
        extraFlags = [ "--listen=127.0.0.1:8000" ];
      };

      systemd.services.restic-rest-server = {
        after = lib.mkForce ([
          "network.target"
        ] ++ restServerSvcConfig.unitConfig.After);
        requires = lib.mkForce (restServerSvcConfig.unitConfig.Requires);

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          StateDirectory = ifDefaultData "restic";
        };
      };

      systemd.sockets.restic-rest-server.enable = false;

      environment.persistence."/nix/persist/restic-server" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "restic"; group = "restic"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
