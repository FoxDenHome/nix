{ superfan, lib, config, ... }:
let
  svcConfig = config.foxDen.services.superfan;

  superfanPkg = superfan.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.superfan.enable = lib.mkEnableOption "SuperMicro fan controller";

  config = lib.mkIf svcConfig.enable {
    systemd.services.superfan = {
      description = "SuperMicro fan controller daemon";

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        TimeoutStartSec = "300";
        ExecStart = ["${superfanPkg}/bin/superfan"];
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
