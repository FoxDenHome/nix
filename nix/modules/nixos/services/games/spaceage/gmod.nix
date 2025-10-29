{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.spaceage-gmod;
in
{
  options.foxDen.services.spaceage-gmod = services.mkOptions { svcName = "spaceage-gmod"; name = "SpaceAge GMod"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.make {
      inherit pkgs config svcConfig;
      name = "spaceage-gmod";
    }).config
    {
      systemd.services.spaceage-gmod = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        confinement.packages = with pkgs; [
          steamcmd
          starlord
          git
          coreutils
        ];
        path = [
          steamcmd
          starlord
          git
          coreutils
        ];

        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "spaceage-gmod";
          EnvironmentFile = [ (config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.spaceage-gmod.path) ];
          WorkingDirectory = "/var/lib/spaceage-gmod";
          Environment = [
            "STARLORD_CONFIG=spaceage_forlorn"
            "HOME=/var/lib/spaceage-gmod"
          ];
          Type = "simple";
          ExecStart = [ "${pkgs.starlord}/bin/starlord" ];
        };
      };

      sops.secrets.spaceage-gmod = config.lib.foxDen.sops.mkIfAvailable { };
    }
  ]);
}
