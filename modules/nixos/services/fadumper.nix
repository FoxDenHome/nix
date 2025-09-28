{ foxDenLib, pkgs, lib, config, fadumper, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.fadumper;

  faDumperPkg = fadumper.packages.${config.nixpkgs.hostPlatform.system}.default;
  faDumperDir = "${faDumperPkg}/lib/node_modules/fadumper";
in
{
  options.foxDen.services.fadumper = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/fadumper";
      description = "Directory to store FADumper data";
    };
  } // (services.http.mkOptions { svcName = "fadumper"; name = "FADumper"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "fadumper-api";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "fadumper-refresh";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-fadumper-api";
      target = "reverse_proxy http://127.0.0.1:8001";
    }).config
    {
      foxDen.services.opensearch.enable = true;
      foxDen.services.opensearch.users.fadumper = {
        indexPatterns = [ "fa_*" ];
      };
      foxDen.services.opensearch.services = [ "fadumper-api" "fadumper-refresh" ];

      users.users.fadumper = {
        isSystemUser = true;
        description = "FADumper service user";
        group = "fadumper";
      };
      users.groups.fadumper = {};

      systemd.services.fadumper-api = {
        confinement.packages = [
          faDumperPkg
        ];
        path = [ pkgs.nodejs_24 ];

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          User = "fadumper";
          Group = "fadumper";
          
          Type = "simple";
          ExecStart = [ "${pkgs.nodejs_24}/bin/node ./dist/api/index.js" ];
          WorkingDirectory = faDumperDir;
          StateDirectory = "fadumper";

          Environment = [
            "DOWNLOAD_PATH=${svcConfig.dataDir}"
            "HOST=0.0.0.0"
          ];
        };

        wantedBy = ["multi-user.target"];
      };

      systemd.services.fadumper-refresh = {
        confinement.packages = [
          faDumperPkg
        ];
        path = [ pkgs.nodejs_24 ];

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          User = "fadumper";
          Group = "fadumper";
          
          Type = "simple";
          ExecStart = [ "./looper.sh" ];
          WorkingDirectory = faDumperDir;
          StateDirectory = "fadumper";

          Environment = [
            "DOWNLOAD_PATH=${svcConfig.dataDir}"
          ];
        };
      };

      environment.systemPackages = [ faDumperPkg ];
    }
  ]);
}
