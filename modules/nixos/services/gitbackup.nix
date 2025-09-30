{ foxDenLib, pkgs, lib, config, gitbackup, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.gitbackup;

  defaultDataDir = "/var/lib/private/gitbackup";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  gitbackupPkg = gitbackup.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.gitbackup = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store gitbackup data";
    };
  } // (services.http.mkOptions { svcName = "gitbackup"; name = "Git backup"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "gitbackup";
      inherit svcConfig pkgs config;
    }).config
    {
      systemd.services.gitbackup = {
        confinement.packages = [
          pkgs.git
        ];

        path = [
          pkgs.git
        ];

        serviceConfig = {
          DynamicUser = true;
          Type = "simple";

          Environment = [
            "GITHUB_ORGANIZATIONS=foxCaves,FoxDenHome,FoxBukkit,MoonHack,PawNode,SpaceAgeMP,WSVPN"
            "BACKUP_ROOT=/data"
          ];

          EnvironmentFile = config.lib.foxDen.sops.mkGithubTokenPath;

          BindPaths = [
            "${svcConfig.dataDir}:/data"
          ];

          ExecStart = [ "${gitbackupPkg}/bin/gitbackup-loop" ];

          StateDirectory = ifDefaultData "gitbackup";
        };

        wantedBy = [ "multi-user.target" ];
      };
    }
  ]);
}
