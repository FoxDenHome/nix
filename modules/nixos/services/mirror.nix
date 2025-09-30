{ foxDenLib, nginx-mirror, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mirror;

  defaultDataDir = "/var/lib/mirror";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  nginxPkg = nginx-mirror.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.mirror = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store mirror data";
    };
  } // (services.http.mkOptions { svcName = "mirror"; name = "Mirror server"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "mirror";
      inherit svcConfig pkgs config;
    }).config
    {
      users.users.mirror = {
        isSystemUser = true;
        description = "mirror service user";
        group = "mirror";
      };
      users.groups.mirror = {};

      systemd.services.mirror = {
        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          User = "mirror";
          Group = "mirror";

          ExecStart = [ "${pkgs.nginx}/bin/nginx -g 'daemon off;' -c ${nginxPkg}/conf/nginx.conf" ];
          WorkingDirectory = "${nginxPkg}/conf";

          StateDirectory = ifDefaultData "mirror";
        };

        wantedBy = [ "multi-user.target" ];
      };

      environment.persistence."/nix/persist/mirror" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "mirror"; group = "mirror"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
