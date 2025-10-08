{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.unifi.user;
    group = config.services.unifi.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.unifi;
in
{
  options.foxDen.services.unifi = {
    enableCaddy = lib.mkEnableOption "Caddy reverse proxy for UniFi Web UI";
  } // (services.http.mkOptions { svcName = "unifi"; name = "UniFi Network Controller"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "unifi";
      inherit svcConfig pkgs config;
    }).config
    (lib.mkIf svcConfig.enableCaddy (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-unifi";
      target = "reverse_proxy http://127.0.0.1:8443";
    }).config)
    {
      services.unifi = {
        enable = true;
      };

      systemd.services.unifi = {
        confinement.packages = [
          config.services.unifi.unifiPackage
          config.services.unifi.mongodbPackage
          config.services.unifi.jrePackage
        ];
        serviceConfig = {
          StateDirectory = "unifi";
        };
      };

      environment.persistence."/nix/persist/unifi" = {
        hideMounts = true;
        directories = [
          (mkDir "/var/lib/unifi")
        ];
      };
    }
  ]);
}
