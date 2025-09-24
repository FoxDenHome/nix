{ nixpkgs, lib, config, pkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };
in
{
  options.foxDen.services.services = with lib.types; lib.mkOption {
    type = attrsOf (submodule {
      options = {
        host = lib.mkOption {
          type = str;
        };
      };
    });
    default = {};
  };

  config.systemd.services = lib.attrsets.mapAttrs (svc: svcConfig:
  let
    info = hosts.mkHostInfo svcConfig.host;
  in {
    unitConfig = {
      Requires = [ info.unit ];
      BindsTo = [ info.unit ];
      After = [ info.unit ];
    };

    serviceConfig = {
      NetworkNamespacePath = info.namespace;
      DevicePolicy = "closed";
      PrivateTmp = true;
      PrivateMounts = true;
      ProtectSystem = "strict";
      ProtectHome = "tmpfs";
      Restart = lib.mkForce "always";
    };
  }) config.foxDen.services.services;
}
