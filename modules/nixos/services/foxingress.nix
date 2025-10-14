{ pkgs, lib, config, foxDenLib, ... }:
let
  services = foxDenLib.services;
  svcConfig = config.foxDen.services.foxingress;

  configFile = if svcConfig.configText != "" then (pkgs.writers.writeText "config.yml" svcConfig.configText) else (pkgs.writers.writeYAML "config.yml" svcConfig.config);
in
{
  options.foxDen.services.foxingress = {
    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.any;
    };
    configText = lib.mkOption {
      type = lib.types.str;
      description = "Raw text configuration for foxIngress, alternative to 'config' option.";
      default = "";
    };
  } // services.mkOptions { svcName = "foxingress"; name = "foxIngress"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.make {
      inherit pkgs config svcConfig;
      name = "foxingress";
    }).config
    {
      systemd.services.foxingress = {
        serviceConfig = {
          Type = "simple";
          Restart = "no";
          BindReadOnlyPaths = [ configFile ];
          Environment = [
            "CONFIG_FILE=${configFile}"
          ];
          ExecStart = [ "${pkgs.foxingress}/bin/foxIngress" ];
        };

        wantedBy = [ "multi-user.target" ];
      };
    }
  ]);
}
