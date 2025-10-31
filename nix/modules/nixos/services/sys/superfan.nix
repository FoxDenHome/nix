{ pkgs, foxDenLib, lib, config, ... }:
let
  svcConfig = config.foxDen.services.superfan;
in
{
  options.foxDen.services.superfan.enable = lib.mkEnableOption "SuperMicro fan controller";

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.make {
      inherit pkgs config svcConfig;
      name = "superfan";
      devices = [
        "/dev/ipmi0"
      ];
    }).config
    {
      systemd.services.superfan = {
        description = "SuperMicro fan controller daemon";

        path = [ pkgs.lm_sensors ];
        confinement.packages = [ pkgs.lm_sensors ];

        serviceConfig = {
          BindPaths = [ "/var/lock" ];
          Type = "simple";
          Restart = "always";
          TimeoutStartSec = "30";
          ExecStart = ["${pkgs.superfan}/bin/superfan"];
        };

        wantedBy = [ "multi-user.target" ];
      };
    }
  ]);
}
