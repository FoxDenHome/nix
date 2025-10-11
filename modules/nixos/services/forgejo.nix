{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.forgejo.user;
    group = config.services.forgejo.group;
    mode = "u=rwx,g=,o=";
  });

  defaultDataDir = "/var/lib/forgejo";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  svcConfig = config.foxDen.services.forgejo;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
  proto = if svcConfig.tls then "https" else "http";

  baseServiceConfig = {
    BindPaths = [ config.services.forgejo.stateDir ];
    StateDirectory = ifDefaultData "forgejo";
  };

  baseSystemdConfig = {
    requires = [ "forgejo-pre.service" ];
    after = [ "forgejo-pre.service" ];
    serviceConfig = baseServiceConfig;  
  };
in
{
  options.foxDen.services.forgejo = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store git data";
    };
  } // services.http.mkOptions { svcName = "forgejo"; name = "Forgejo git server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "forgejo";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "forgejo-secrets";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "forgejo-dump";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-forgejo";
      target = "reverse_proxy http://127.0.0.1:8096";
    }).config
    {
      services.forgejo = {
        enable = true;
        stateDir = svcConfig.dataDir;
        database = {
          createDatabase = false;
          name = "forgejo";
          user = "forgejo";
          socket = "/run/postgresql/.s.PGSQL.5432";
        };
        lfs = {
          enable = true;
        };
        settings = {
          server = {
            PROTOCOL = "fcgi";
            DOMAIN = hostName;
            HTTP_PORT = 3000;
            ROOT_URL = "${proto}://${hostName}";
          };
          session = {
            COOKIE_SECURE = svcConfig.tls;
          };
        };
      };

      systemd.services.forgejo-pre = {
        serviceConfig = baseServiceConfig // {
          ExecStart = [
            "${pkgs.coreutils}/bin/mkdir -p ${config.services.forgejo.customDir} ${config.services.forgejo.dump.backupDir} ${config.services.forgejo.lfs.contentDir} ${config.services.forgejo.repositoryRoot}"
          ];
          Type = "oneshot";
          RemainAfterExit = true;
        };

        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.forgejo = baseSystemdConfig;
      systemd.services.forgejo-secrets = baseSystemdConfig;

      foxDen.services.postgresql.services = [
        {
          name = "forgejo";
          targetService = "forgejo";
        }
      ];

      environment.persistence."/nix/persist/forgejo" = ifDefaultData {
        hideMounts = true;
        directories = [
          (mkDir defaultDataDir)
        ];
      };
    }
  ]);
}
