{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.nzbget.user;
    group = config.services.nzbget.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.nzbget;
in
{
  options.foxDen.services.nzbget = {
    downloadsDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/nzbget/downloads";
      description = "Directory to store completed NZBGet downloads";
    };
    enableCaddy = lib.mkEnableOption "Caddy reverse proxy for NZBGet Web UI";
  } // (services.http.mkOptions { svcName = "nzbget"; name = "NZBGet Usenet Client"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "nzbget";
      inherit svcConfig pkgs config;
    }).config
    (lib.mkIf svcConfig.enableCaddy (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-nzbget";
      target = "reverse_proxy http://127.0.0.1:6789";
    }).config)
    {
      services.nzbget = {
        enable = true;
        settings = {
          MainDir = "/var/lib/nzbget";
          DestDir = svcConfig.downloadsDir;
        };
        group = "share";
      };

      systemd.services.nzbget-pre = {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = [
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/nzbget/downloads"
          ];

          User = config.services.nzbget.user;
          Group = config.services.nzbget.group;

          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      systemd.services.nzbget = {
        requires = [ "nzbget-pre.service" ];
        bindsTo = [ "nzbget-pre.service" ];
        after = [ "nzbget-pre.service" ];

        serviceConfig = {
          BindPaths = [
            svcConfig.downloadsDir
          ];
          StateDirectory = "nzbget";
        };
      };

      environment.persistence."/nix/persist/nzbget" = {
        hideMounts = true;
        directories = [
          (mkDir config.services.nzbget.settings.MainDir)
        ];
      };
    }
  ]);
}
