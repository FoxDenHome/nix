{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.minecraft;

  defaultDataDir = "/var/lib/minecraft";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);
in
{
  options.foxDen.services.minecraft = with lib.types; {
    jrePackage = lib.mkOption {
      type = package;
      description = "JRE package to use for running Minecraft server";
    };
    dataDir = lib.mkOption {
      type = path;
      default = defaultDataDir;
      description = "Directory to store Minecraft data";
    };
    runScript = lib.mkOption {
      type = str;
      default = "start.sh";
      description = "Path to the Minecraft server run script (relative to server dir)";
    };
  } // (services.http.mkOptions { svcName = "minecraft"; name = "Minecraft server"; });

  # TODO: Make modpack a package and actually build it and only take the world

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      inherit svcConfig pkgs config;
      name = "minecraft";
    }).config
    {
      systemd.services.minecraft = {
        confinement.packages = [
          svcConfig.jrePackage
        ];
        path = [
          svcConfig.jrePackage
        ];

        serviceConfig = {
          User = "minecraft";
          Group = "minecraft";

          Environment = {
            "SERVER_DIR" = "/data";
          };

          BindPaths = [
            "${svcConfig.dataDir}:/data"
          ];
          WorkingDirectory = "/data";

          ExecStart = [
            "/data/${svcConfig.runScript}"
          ];
          StateDirectory = ifDefaultData "minecraft";
        };
      };

      environment.persistence."/nix/persist/minecraft" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
