{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.deluge.user;
    group = config.services.deluge.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.deluge;
in
{
  options.foxDen.services.deluge = {
    downloadsDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/deluge/downloads";
      description = "Directory to store Deluge downloads";
    };
  } // (services.http.mkOptions { svcName = "deluge"; name = "Deluge BitTorrent Client"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "deluged";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "delugeweb";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-deluge";
      target = "reverse_proxy http://127.0.0.1:8112";
    }).config
    {
      sops.secrets.delugeAuthFile = config.lib.foxDen.sops.mkIfAvailable {};

      services.deluge = {
        enable = true;
        web = {
          enable = true;
        };
        dataDir = "/var/lib/deluge";
        config = {
          download_location = "/downloads";
        };
        declarative = true;
        group = "share";
        authFile = "/var/lib/deluge/auth";
      };

      systemd.services.deluge-pre = {
        wantedBy = [ "multi-user.target" "deluged.service" "delugeweb.service" ];
        before = [ "deluged.service" "delugeweb.service" ];

        serviceConfig = {
          LoadCredential = "auth:${config.sops.secrets.delugeAuthFile.path}";

          ExecStart = [
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/deluge/downloads"
            "${pkgs.coreutils}/bin/cp \${CREDENTIALS_DIRECTORY}/auth /var/lib/deluge/auth"
            "${pkgs.coreutils}/bin/chmod 600 /var/lib/deluge/auth"
          ];

          User = config.services.deluge.user;
          Group = config.services.deluge.group;

          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      systemd.services.deluged.serviceConfig = {
        BindPaths = [
          config.services.deluge.dataDir
          "${svcConfig.downloadsDir}:/downloads"
        ];
      };

      systemd.services.delugeweb.serviceConfig = {
        BindPaths = [
          config.services.deluge.dataDir
          "${svcConfig.downloadsDir}:/downloads"
        ];
      };

      environment.persistence."/nix/persist/deluge" = {
        hideMounts = true;
        directories = [
          (mkDir config.services.deluge.dataDir)
        ];
      };
    }
  ]);
}
