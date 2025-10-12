{ nixpkgs, foxDenLib, ... }:
let
  services = foxDenLib.services;
in
{
  nixosModule = { ... }:
  {

  };

  mkOptions = (inputs@{ ... } : with nixpkgs.lib.types; {
    requirePass = nixpkgs.lib.mkOption {
      type = nullOr str;
      default = null;
    };
    requirePassFile = nixpkgs.lib.mkOption {
      type = nullOr path;
      default = null;
    };
  } // (services.mkOptions inputs));

  make = (inputs@{ config, svcConfig, pkgs, ... }:
    let
      name = "redis-${inputs.name}";
      svc = services.mkNamed name inputs;
    in
    {
      config = (nixpkgs.lib.mkMerge [
        svc.config
        {
          services.redis.servers.${inputs.name} = {
            enable = true;
            port = 6379;
            bind = "127.0.0.1";
            requirePass = svcConfig.requirePass;
            requirePassFile = svcConfig.requirePassFile;
          };

          systemd.services.${name} = {
            serviceConfig = {
              StateDirectory = name;
            };
          };
        }
      ]);
    });
}
