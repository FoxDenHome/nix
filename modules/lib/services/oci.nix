{ foxDenLib, nixpkgs, ... }:
let
    mkNamed = (svc: inputs@{ oci, systemd, svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.sops.secrets.aurbuildGpgPin = config.lib.foxDen.sops.mkIfAvailable {};

      config.virtualisation.oci-containers.containers."${svc}" = nixpkgs.lib.mkMerge [
        {
          autoStart = nixpkgs.lib.mkDefault true;
          pull = nixpkgs.lib.mkDefault "always";
          networks = [ "ns:${host.namespacePath}" ];
        }
        oci
      ];

      config.systemd.services."podman-${svc}" = nixpkgs.lib.mkMerge [
        {
          unitConfig = {
            Requires = [ host.unit ];
            BindsTo = [ host.unit ];
            After = [ host.unit ];
          };
        }
        systemd
      ];
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
