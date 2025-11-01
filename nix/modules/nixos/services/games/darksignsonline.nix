{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.darksignsonline;
in
{
  options.foxDen.services.darksignsonline = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the service";
    };
    tls = lib.mkEnableOption "Enable TLS for the service";
  } // services.mkOptions { svcName = "darksignsonline"; name = "Dark Signs Online"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "darksignsonline";
      oci = {
        image = "ghcr.io/doridian/darksignsonline/server:latest";
        volumes = [
          "nginx:/var/lib/nginx"
          "wiki:/var/www/wiki"
        ];
        environment = {
          "DOMAIN" = svcConfig.domain;
          "HTTP_MODE" = if svcConfig.tls then "https" else "http";
          "TRUSTED_PROXIES" = lib.concatStringsSep " " config.foxDen.services.trustedProxies;
          "SMTP_FROM" = "noreply@${svcConfig.domain}";
          "MYSQL_HOST" = "127.0.0.1";
          "MYSQL_PORT" = "3306";
          "MYSQL_PASSWORD" = "";
          "MYSQL_DATABASE" = "darksignsonline";
          "MYSQL_USERNAME" = "darksignsonline";
        } ++ config.lib.mysql.mkEnvironmentAttrs;
        environmentFiles = [
          (config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.darksignsonline.path)
        ];
      };
    }).config
    {
      sops.secrets.darksignsonline = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "darksignsonline";
        group = "darksignsonline";
      };

      foxDen.hosts.hosts.${svcConfig.host}.webservice.enable = true;

      foxDen.services.mysql = {
        enable = true;
        services = [
          {
            name = "darksignsonline";
            databases = [
              "darksignsonline_wiki"
            ];
            proxy = true;
            targetService = "podman-darksignsonline";
          }
        ];
      };
    }
  ]);
}
