{ foxDenLib, ... }:
let
    mkNamed = (svc: inputs@{ image, svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.sops.secrets.aurbuildGpgPin = config.lib.foxDen.sops.mkIfAvailable {};

      config.virtualisation.oci-containers.containers."${svc}" = {
        image = image;
        autoStart = true;
        networks = [ "ns:${host.namespacePath}" ];

        volumes = config.lib.foxDen.sops.mkIfAvailable  [
          "${config.sops.secrets.aurbuildGpgPin.path}:/gpg/pin:ro"
        ];

        environment = {
          "GPG_KEY_ID" = "45B097915F67C9D68C19E5747B0F7660EAEC8D49";
        };
      };

      config.systemd.services."podman-${svc}" = {
        unitConfig = {
          Requires = [ host.unit ];
          BindsTo = [ host.unit ];
          After = [ host.unit ];
        };
      };
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
