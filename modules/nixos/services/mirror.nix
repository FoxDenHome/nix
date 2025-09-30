{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mirror;

  defaultDataDir = "/var/lib/mirror";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);
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
      name = "nginx-mirror";
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

          ExecStart = [ "${pkgs.nginx}/bin/nginx -g 'daemon off;' -c /etc/foxden/mirror/nginx.conf" ];
          WorkingDirectory = svcConfig.dataDir;

          StateDirectory = ifDefaultData "mirror";
        };

        wantedBy = [ "multi-user.target" ];
      };

      environment.etc."foxden/mirror/nginx.conf" = {
        text = ''
          
        '';
        user = "root";
        group = "root";
        mode = "u=rw,g=r,o=";
      };

      environment.persistence."/nix/persist/kiwix" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "kiwix"; group = "kiwix"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
