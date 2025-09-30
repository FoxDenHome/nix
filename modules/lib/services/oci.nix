{ nixpkgs, foxDenLib, ... }:
let
    mkNamed = (svc: inputs@{ svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.virtualization.oci-containers.containers."${svc}" = {
        image = svcConfig.image;
        autoStart = true;
        restartPolicy = "always";
        networks = [ "ns:${host.namespacePath}" ];
      };
    }));
in
{
  mkOptions = inputs: (foxDenLib.services.mkOption inputs) // (with nixpkgs.lib.types; {
    image = nixpkgs.lib.mkOption {
      type = str;
    };
  });
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
