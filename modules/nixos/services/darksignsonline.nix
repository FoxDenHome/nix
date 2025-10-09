{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.darksignsonline;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
  proto = if svcConfig.tls then "https" else "http";
in
{
  options.foxDen.services.darksignsonline = services.mkOptions { svcName = "darksignsonline"; name = "Dark Signs Online"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "darksignsonline";
      oci = {
        image = "ghcr.io/doridian/darksignsonline/server:latest";
        volumes = [
          "caddy:/var/lib/caddy"
          "wiki:/var/www/wiki"
        ];
        environment = {
          "DOMAIN" = hostName;
          "DB_USERNAME" = "$MYSQL_USERNAME";
          "DB_PASSWORD" = "";
          "DB_DATABASE" = "$MYSQL_DATABASE";
          "SMTP_FROM" = "noreply@${hostName}";
        };
        environmentFiles = [
          (config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.darksignsonline.path);
        ];
      }
    }).config
    {
      sops.secrets.darksignsonline = config.lib.foxDen.sops.mkIfAvailable {};

      foxDen.services.mysql = {
        services = [ "podman-darksignsonline" ];
        dbUsers = [ "darksignsonline" ];
      };
    }
  ]);
}
