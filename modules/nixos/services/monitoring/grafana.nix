{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = "grafana";
    group = "grafana";
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.grafana;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
  proto = if svcConfig.tls then "https" else "http";
in
{
  options.foxDen.services.grafana = {

  } // services.http.mkOptions { svcName = "grafana"; name = "Grafana monitoring server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "grafana";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-grafana";
      target = ''
        reverse_proxy 127.0.0.1:3000
      '';
    }).config
    {
      services.grafana = {
        enable = true;
        dataDir = "/var/lib/grafana";
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            root_url = "${proto}://${hostName}";
          };
          database = {
            name = "grafana";
            user = "grafana";
            host = config.foxDen.services.mysql.socketPath;
            type = "mysql";
          };
          security = {
            cookie_secure = svcConfig.tls;
          };
          smtp = {
            enabled = false;
          };
        };
      };

      sops.secrets.grafana = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "grafana";
        group = "grafana";
      };

      systemd.services.grafana = {
        confinement.packages = [
          pkgs.coreutils
        ];

        serviceConfig = {
          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.grafana.path;
          StateDirectory = "grafana";
        };
      };

      foxDen.services.mysql.services = [
        {
          name = "grafana";
          targetService = "grafana";
        }
      ];

      environment.persistence."/nix/persist/grafana" = {
        hideMounts = true;
        directories = [
          (mkDir "/var/lib/grafana")
        ];
      };
    }
  ]);
}
