{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.nasweb;
in
{
  options.foxDen.services.nasweb = {
    root = lib.mkOption {
      type = lib.types.path;
      description = "Root directory to serve files from";
    };
  } // (services.http.mkOptions { svcName = "nasweb"; name = "NAS web interface"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "nasweb";
      target = ''
        root * /nas
        file_server {
          browse
        }
      '';
      extraConfig = ''
        handle /guest/* {
          root * /nas
          file_server
        }
      '';
    }).config
    {
      systemd.services.nasweb.serviceConfig = {
        BindReadOnlyPaths = [
          "${svcConfig.root}:/nas"
        ];
      };
    }
  ]);
}
