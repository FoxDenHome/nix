{ foxDenLib, ... }:
let
    mkNamed = (svc: inputs@{ image, svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.virtualisation.oci-containers.containers."${svc}" = {
        image = image;
        autoUpdate = "registry";
        autoStart = true;
        networks = [ "ns:${host.namespacePath}" ];
      };
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
