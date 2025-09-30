{ foxDenLib, nginx-mirror, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mirror;
  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);

  mirrorPkg = nginx-mirror.packages.${config.nixpkgs.hostPlatform.system}.default;

  nginxPkg = pkgs.nginxQuic.override {
    modules = [
      pkgs.nginxModules.njs
      pkgs.nginxModules.fancyindex
    ];
  };

  svcDomain = "${primaryInterface.dns.name}.${primaryInterface.dns.zone}";
  svcRootDomain = lib.strings.removePrefix "mirror." svcDomain;
in
{
  options.foxDen.services.mirror = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/mirror/data";
      description = "Directory to store mirror data";
    };

    archMirrorId = lib.mkOption {
      type = lib.types.str;
    };
  } // (services.http.mkOptions { svcName = "mirror"; name = "Mirror server"; });

  # TODO: Auto-add CNAMEs

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "mirror-nginx";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "mirror-rsyncd";
      inherit svcConfig pkgs config;
    }).config
    {
      users.users.mirror = {
        isSystemUser = true;
        description = "mirror service user";
        group = "mirror";
      };
      users.groups.mirror = {};

      systemd.services.mirror-nginx = {
        confinement.packages = [
          mirrorPkg
        ];

        serviceConfig = {
          BindReadOnlyPaths = [
            "${mirrorPkg}:/njs"
            "${svcConfig.dataDir}:/data"
          ];

          PrivateUsers = false; # needed for the capabilities sadly
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];

          Environment = [
            "ROOT_DOMAIN=${svcRootDomain}"
            "ARCH_MIRROR_ID=${svcConfig.archMirrorId}"
            "RESOLVERS=${lib.strings.concatStringsSep " " hostCfg.nameservers}"
          ];

          User = "mirror";
          Group = "mirror";

          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/mirror/ssl ${svcConfig.dataDir}"
            "${pkgs.nodejs_24}/bin/node /njs/lib/util/renderconf.js"
          ];
          ExecStart = [ "${nginxPkg}/bin/nginx -g 'daemon off;' -p /tmp/ngxconf -c nginx.conf" ];

          StateDirectory = "mirror";
        };

        wantedBy = [ "multi-user.target" ];
      };

      environment.etc."foxden/mirror/rsyncd.conf" = {
        text = ''
          use chroot = no
          max connections = 128
          log file = /dev/stdout
          pid file = /tmp/rsyncd.pid
          lock file = /tmp/rsyncd.lock
          read only = yes
          numeric ids = yes
          reverse lookup = no
          forward lookup = no

          exclude = /.dori-local /_dori-static /.well-known

          [archlinux]
                  path = /data/archlinux

          [cachyos]
                  path = /data/cachyos

          [foxdenaur]
                  path = /data/foxdenaur
        '';
      };

      systemd.services.mirror-rsyncd = {
        serviceConfig = {
          BindReadOnlyPaths = (foxDenLib.services.mkEtcPaths [
            "foxden/mirror"
          ])
          ++ [
            "${svcConfig.dataDir}:/data"
          ];

          ExecStart = [ "${pkgs.rsync}/bin/rsync --daemon --no-detach --config=/etc/foxden/mirror/rsyncd.conf" ];

          User = "mirror";
          Group = "mirror";

          StateDirectory = "mirror";
        };

        wantedBy = [ "multi-user.target" ];
      };

      environment.persistence."/nix/persist/mirror" = {
        hideMounts = true;
        directories = [
          { directory = "/var/lib/mirror/data"; user = "mirror"; group = "mirror"; mode = "u=rwx,g=,o="; }
          { directory = "/var/lib/mirror"; user = "mirror"; group = "mirror"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
