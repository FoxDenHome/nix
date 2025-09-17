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

      modules = (map import
                  (nixpkgs.lib.filter isNixFile
                    (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos)));

      # Finds things like inputs.impermanence.nixosModules.impermanence
      # Some modules might not contain this, so we filter out the empty strings
      inputModules = nixpkgs.lib.filter (val: val != "")
                       (map (val: nixpkgs.lib.attrsets.attrByPath [ "nixosModules" val.name ] "" val.value)
                         (nixpkgs.lib.attrsToList inputs));

      machineFiles = nixpkgs.lib.filter isNixFile
                      (nixpkgs.lib.filesystem.listFilesRecursive ./systems);

      mkMachine = path: let
        machine = import path;

        splitPath = nixpkgs.lib.path.splitRoot path;
        components = nixpkgs.lib.path.subpath.components splitPath.subpath;
        componentsLength = nixpkgs.lib.lists.length components;

        hostname = nixpkgs.lib.strings.removeSuffix ".nix"
                    (nixpkgs.lib.strings.elemAt components (componentsLength - 1)); # e.g. bengalfox
        system = nixpkgs.lib.strings.elemAt components (componentsLength - 2); # e.g. x86_64-linux
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
            machine
          ] ++ inputModules ++ modules;
        };
      };
    in
    (nixpkgs.lib.attrsets.listToAttrs (map mkMachine machineFiles));
  };
}
