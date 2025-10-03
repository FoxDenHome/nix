{ nixpkgs-unstable, config, ... } :
{
  services.kanidm = {
    enableClient = true;

    package = nixpkgs-unstable.outputs.legacyPackages.${config.nixpkgs.hostPlatform.system}.kanidm_1_7; # TODO: pkgs. once 25.11

    clientSettings = {
      uri = "https://auth.foxden.network";
      verify_ca = true;
      verify_hostnames = true;
    };
  };
}
