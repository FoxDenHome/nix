{
  description = "FoxDen Nix config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs@{ nixpkgs, ... }:
  {
    nixosConfigurations =
    let
      isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

      moduleClasses = nixpkgs.lib.filter (nixpkgs.lib.attrsets.hasAttr "module")
                        (map import
                          (nixpkgs.lib.filter isNixFile
                            (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos)));

      modules = (map (val: val.module) moduleClasses);

      # Finds things like inputs.impermanence.nixosModules.impermanence
      # Some modules might not contain this, so we filter out the empty strings
      inputModules = nixpkgs.lib.filter (val: val != "")
                       (map (val: nixpkgs.lib.attrsets.attrByPath [ "nixosModules" val.name ] "" val.value)
                         (nixpkgs.lib.attrsToList inputs));

      machineFiles = nixpkgs.lib.filter isNixFile
                      (nixpkgs.lib.filesystem.listFilesRecursive ./systems);

      mkMachine = path: let
        machine = import path;

        components = nixpkgs.lib.path.subpath.components
                      (nixpkgs.lib.strings.removePrefix (toString ./. + "/") (toString path));

        hostname = nixpkgs.lib.strings.removeSuffix ".nix" (nixpkgs.lib.strings.elemAt components 2); # e.g. bengalfox
        system = nixpkgs.lib.strings.elemAt components 1; # e.g. x86_64-linux
      in
      {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ({ ... }: {
              networking.hostName = hostname;
              nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system;
            })
            machine.module
          ] ++ inputModules ++ modules;
        };
      };
    in
    (nixpkgs.lib.attrsets.listToAttrs (map mkMachine machineFiles));
  };
}
