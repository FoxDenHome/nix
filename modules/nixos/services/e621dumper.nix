{ foxDenLib, pkgs, lib, config, e621dumper, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.e621dumper;

  e621DumperPkg = e621dumper.packages.${config.nixpkgs.hostPlatform.system}.default;
  e621DumperDir = "${e621DumperPkg}/lib/node_modules/e621dumper";

  defaultDataDir = "/var/lib/e621dumper";
  ifDefaultData = lib.mkIf (config.foxDen.services.fadumper.dataDir == defaultDataDir);
in
{
  options.foxDen.services.e621dumper = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store e621Dumper data";
    };
  } // (services.http.mkOptions { svcName = "e621dumper"; name = "e621Dumper"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "e621dumper-api";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "e621dumper-refresh";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-e621dumper-api";
      target = "reverse_proxy http://127.0.0.1:8001";
    }).config
    {
      foxDen.services.opensearch.enable = true;
      foxDen.services.opensearch.users.e621dumper = {
        indexPatterns = [ "e621dumper_*" ];
      };
      foxDen.services.opensearch.services = [ "e621dumper-api" "e621dumper-refresh" ];

      users.users.e621dumper = {
        isSystemUser = true;
        description = "e621Dumper service user";
        group = "e621dumper";
      };
      users.groups.e621dumper = {};

      sops.secrets.e621dumper = config.lib.foxDen.sops.mkIfAvailable {};

      systemd.services.e621dumper-api = {
        confinement.packages = [
          e621DumperPkg
        ];
        path = [ pkgs.nodejs_24 ];

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          User = "e621dumper";
          Group = "e621dumper";

          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.e621dumper.path;

          Type = "simple";
          ExecStart = [ "${pkgs.nodejs_24}/bin/node ./dist/api/index.js" ];
          WorkingDirectory = e621DumperDir;
          StateDirectory = ifDefaultData "e621dumper";

          Environment = [
            "DOWNLOAD_PATH=${svcConfig.dataDir}"
            "HOST=127.0.0.1"
            "PORT=8001"
          ];
        };

        wantedBy = ["multi-user.target"];
      };

      systemd.services.e621dumper-refresh = {
        confinement.packages = [
          e621DumperPkg
        ];
        path = [ pkgs.nodejs_24 ];

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          User = "e621dumper";
          Group = "e621dumper";

          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.e621dumper.path;
          
          Type = "simple";
          ExecStart = [ "./looper.sh" ];
          WorkingDirectory = e621DumperDir;
          StateDirectory = ifDefaultData "e621dumper";

          Environment = [
            "DOWNLOAD_PATH=${svcConfig.dataDir}"
          ];
        };
      };

      systemd.timers.e621Dumper-refresh = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          AccuracySec = "12h";
          Persistent = true;
        };
      };

      environment.systemPackages = [ e621DumperPkg ];

      environment.persistence."/nix/persist/e621dumper" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "e621dumper"; group = "e621dumper"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
