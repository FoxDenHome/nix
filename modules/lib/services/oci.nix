{ foxDenLib, ... }:
let
    mkNamed = (svc: inputs@{ image, svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.services.podman.containers."${svc}" = {
        image = image;
        autoStart = true;
        networks = [ "ns:${host.namespacePath}" ];
        autoUpdate = "registry";
      };
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
