{ nixpkgs, foxDenLib, ... }:
let
    mkNamed = (svc: inputs@{ svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.virtualisation.oci-containers.containers."${svc}" = {
        image = svcConfig.image;
        autoStart = true;
        networks = [ "ns:${host.namespacePath}" ];
      };
    }));
in
{
  mkOptions = inputs: (foxDenLib.services.mkOptions inputs) // (with nixpkgs.lib.types; {
    image = nixpkgs.lib.mkOption {
      type = str;
    };
  });
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
