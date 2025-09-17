{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { lanzaboote, impermanence, nixpkgs, ... }:
  {
    nixosConfigurations =
    let
      isValidModule = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;
      moduleFiles = nixpkgs.lib.filter isValidModule
                      (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos);
      baseModules = [
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
      ] ++ moduleFiles;

      machineFiles = nixpkgs.lib.filter isValidModule
                      (nixpkgs.lib.filesystem.listFilesRecursive ./systems);

      mkMachine = path: let
        elemAt = nixpkgs.lib.strings.elemAt;

        relPath = nixpkgs.lib.strings.removePrefix (toString ./. + "/") (toString path);
        components = nixpkgs.lib.path.subpath.components (relPath);

        hostname = nixpkgs.lib.strings.removeSuffix ".nix" (elemAt components 2); # e.g. bengalfox;
        system = elemAt components 1; # e.g. x86_64-linux
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
            path
          ] ++ baseModules;
        };
      };
    in
    (nixpkgs.lib.attrsets.listToAttrs (map mkMachine machineFiles));
  };
}
