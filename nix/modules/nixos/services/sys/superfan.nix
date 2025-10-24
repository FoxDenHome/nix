{ pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.superfan;
in
{
  options.foxDen.services.superfan.enable = lib.mkEnableOption "SuperMicro fan controller";

  config = lib.mkIf svcConfig.enable {
    systemd.services.superfan = {
      description = "SuperMicro fan controller daemon";

      path = [
        pkgs.lm_sensors
      ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        TimeoutStartSec = "30";
        ExecStart = ["${pkgs.superfan}/bin/superfan"];
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
