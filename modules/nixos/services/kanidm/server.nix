{ pkgs, lib, config, foxDenLib, ... } :
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.kanidm.server;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
in
{
  options.foxDen.services.kanidm.server = {
    enable = lib.mkEnableOption "kanidm server";
  } // (services.http.mkOptions { svcName = "kanidm"; name = "Kanidm server"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "kanidm";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-kanidm";
      target = ''
        @denied {
          path /v1/*
          not client_ip private_ranges
          not path /v1/auth /v1/auth/* /v1/self /v1/self/* /v1/credential /v1/credential/* /v1/jwk /v1/jwk/* /v1/reauth /v1/reauth/* /v1/oauth2 /v1/oauth2/*
        }
        respond @denied "foxden.network intranet only" 403

        reverse_proxy https://127.0.0.1:8443 {
          transport http {
            tls
            tls_insecure_skip_verify
          }
        }
      '';
    }).config
    {
      services.kanidm.enableServer = true;
      services.kanidm.serverSettings = {
        origin = "https://${hostName}";
        domain = hostName;

        tls_chain = "/var/lib/kanidm/server/${hostName}.crt";
        tls_key = "/var/lib/kanidm/server/${hostName}.key";

        http_client_address_info.x-forwarded-for = ["127.0.0.1" "127.0.0.0/8"];
      };

      systemd.services.kanidm = {
        serviceConfig = {
          LoadCredential = [
            "/var/lib/foxden/caddy-kanidm/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.crt"
            "/var/lib/foxden/caddy-kanidm/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.key"
          ];
          ExecStartPre = [
            "${pkgs.coreutils}/bin/cp -f \${CREDENTIALS_DIRECTORY}/* /var/lib/kanidm/"
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/kanidm/backups"
          ];
          StateDirectory = "kanidm";
        };
      };

      environment.persistence."/nix/persist/kanidm" = {
        hideMounts = true;
        directories = [
          { directory = "/var/lib/kanidm"; user = "kanidm"; group = "kanidm"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
