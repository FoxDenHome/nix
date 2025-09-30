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
      services.deluge.enable = true;
      services.deluge.web.enable = true;
      services.deluge.group = "share";

      systemd.services.deluged.serviceConfig = {
        BindPaths = [
          config.services.deluge.dataDir
          "${svcConfig.downloadsDir}:/downloads"
        ];
        ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${svcConfig.downloadsDir}" ];
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
