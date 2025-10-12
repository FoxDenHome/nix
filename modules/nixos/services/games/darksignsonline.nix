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
  } // services.mkOptions { svcName = "darksignsonline"; name = "Dark Signs Online"; };

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
          "DOMAIN" = svcConfig.domain;
          "SMTP_FROM" = "noreply@${svcConfig.domain}";
        };
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

      foxDen.services.mysql = {
        enable = true;
        services = [
          {
            name = "darksignsonline";
            proxy = true;
            targetService = "podman-darksignsonline";
          }
        ];
      };
    }
  ]);
}
