{ foxDenLib, nginx-mirror, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mirror;
  hostCfg = foxDenLib.hosts.getByName svcConfig.host;

  defaultDataDir = "/var/lib/mirror";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  mirrorPkg = nginx-mirror.packages.${config.nixpkgs.hostPlatform.system}.default;

  nginxPkg = pkgs.nginxQuic.override {
    modules = [
      pkgs.nginxModules.njs
      pkgs.nginxModules.fancyindex
    ];
  };

  svcDomain = "${hostCfg.dns.name}.${hostCfg.dns.zone}";
  svcRootDomain = lib.strings.removePrefix "mirror." svcDomain;
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
          BindReadOnlyPaths = [
            "${mirrorPkg}:/njs"
          ];

          PrivateUsers = false; # needed for the capabilities sadly
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];

          Environment = [
            "ROOT_DOMAIN=${svcRootDomain}"
            "ARCH_MIRROR_ID=${svcConfig.archMirrorId}"
          ];

          User = "mirror";
          Group = "mirror";

          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/mirror/ssl"
            "${pkgs.nodejs_24}/bin/node /njs/lib/util/renderconf.js"
          ];
          ExecStart = [ "${nginxPkg}/bin/nginx -g 'daemon off;' -p /tmp/ngxconf -c nginx.conf" ];

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
