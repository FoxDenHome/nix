{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.spaceage-gmod;
in
{
  options.foxDen.services.spaceage-gmod = services.mkOptions { svcName = "spaceage-gmod"; name = "SpaceAge GMod"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "spaceage-gmod";
      oci = {
        image = "ghcr.io/spaceagemp/starlord/starlord:latest";
        volumes = [
          "server:/home/server"
        ];
        environment = {
          "ENABLE_SELF_UPDATE" = "true";
        };
        environmentFiles = [
          (config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.spaceage-gmod.path)
        ];
      };
    }).config
    {
      sops.secrets.spaceage-gmod = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "spaceage-gmod";
        group = "spaceage-gmod";
      };
    }
  ]);
}
