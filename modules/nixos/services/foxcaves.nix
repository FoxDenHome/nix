{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.foxcaves;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
in
{
  options.foxDen.services.foxcaves = services.mkOptions { svcName = "foxcaves"; name = "foxCaves"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "foxcaves";
      oci = {
        image = "ghcr.io/foxcaves/foxcaves/foxcaves:latest";
        volumes = [
          "ssl:/etc/letsencrypt"
          (config.lib.foxDen.sops.mkIfAvailable "${config.sops.secrets.foxcaves.path}:/var/www/foxcaves/config/production.lua:ro")
        ];
        environment = {
          "ENVIRONMENT" = "production";
        };
      };
    }).config
    (foxDenLib.services.redis.make {
      inherit pkgs config svcConfig;
      name = "foxcaves";
    }).config
    {
      sops.secrets.foxcaves = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "foxcaves";
        group = "foxcaves";
      };

      foxDen.services.postgresql = {
        enable = true;
        services = [
          {
            name = "foxcaves";
            proxy = true;
            targetService = "podman-foxcaves";
          }
        ];
      };
    }
  ]);
}
