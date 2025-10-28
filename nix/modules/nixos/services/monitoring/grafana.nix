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
        provision = {
          enable = true;
          dashboards.settings.providers = [ {
            options.path = ./grafana/dashboards;
          } ];
          alerting = {
            rules.path = ./grafana/alerts;
            contactPoints.path = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets."grafana-contact-points".path;
            policies.settings.policies = [
              {
                orgId = 1;
                receiver = "Telegram - FoxDen Home";
                group_by = [ "grafana_folder" "alertname" ];
                group_wait = "30s";
                group_interval = "5m";
                repeat_interval = "4h";
              }
            ];
          };

          datasources.settings = {
            prune = true;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                uid = "prometheus";
                access = "proxy";
                url = "http://prometheus.foxden.network:9090";
              }
            ];
          };
        };
        settings = {
          "auth.generic_oauth" = {
            allow_assign_grafana_admin = true;
            allow_sign_up = true;
            api_url = "https://auth.foxden.network/oauth2/openid/grafana/userinfo";
            auth_url = "https://auth.foxden.network/ui/oauth2";
            auto_login = true;
            client_id = "grafana";
            email_attribute_path = "email";
            enabled = true;
            login_attribute_path = "preferred_username";
            name_attribute_path = "name";
            role_attribute_path = "contains(grafana_role[*], 'GrafanaAdmin') && 'GrafanaAdmin' || contains(grafana_role[*], 'Admin') && 'Admin' || contains(grafana_role[*], 'Editor') && 'Editor' || 'Viewer'";
            role_attribute_strict = true;
            scopes = [ "openid" "email" "profile" ];
            token_url = "https://auth.foxden.network/oauth2/token";
            use_pkce = true;
            use_refresh_token = false;
          };
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

      sops.secrets.grafana-contact-points = config.lib.foxDen.sops.mkIfAvailable {
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
          BindReadOnlyPaths = config.lib.foxDen.sops.mkIfAvailable [
            config.sops.secrets."grafana-contact-points".path
          ];
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
