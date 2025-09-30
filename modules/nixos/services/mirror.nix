{ foxDenLib, nginx-mirror, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mirror;

  defaultDataDir = "/var/lib/mirror";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  mirrorPkg = nginx-mirror.packages.${config.nixpkgs.hostPlatform.system}.default;

  nginxPkg = pkgs.nginxQuic.override {
    modules = [
      pkgs.nginxModules.njs
      pkgs.nginxModules.fancyindex
    ];
  };
in
{
  options.foxDen.services.mirror = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = defaultDataDir;
      description = "Directory to store mirror data";
    };

    archMirrorId = lib.mkOption {
      type = lib.types.str;
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
        confinement.packages = [
          mirrorPkg
        ];

        serviceConfig = {
          BindPaths = [
            svcConfig.dataDir
          ];

          PrivateUsers = false; # needed for the capabilities sadly
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];

          User = "mirror";
          Group = "mirror";

          ExecStart = [ "${nginxPkg}/bin/nginx -g 'daemon off;' -p '${mirrorPkg}/lib/node_modules/mirrorweb/conf' -c 'nginx.conf'" ];

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
