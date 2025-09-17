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
      isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

      moduleFiles = nixpkgs.lib.filter isNixFile
                      (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos);
      baseModules = [
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
      ] ++ moduleFiles;

      machineFiles = nixpkgs.lib.filter isNixFile
                      (nixpkgs.lib.filesystem.listFilesRecursive ./systems);
      mkMachine = path: let
        components = nixpkgs.lib.path.subpath.components
                      (nixpkgs.lib.strings.removePrefix (toString ./. + "/") (toString path));

        hostname = nixpkgs.lib.strings.removeSuffix ".nix" (nixpkgs.lib.strings.elemAt components 2); # e.g. bengalfox;
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
            path
          ] ++ baseModules;
        };
      };
    in
    (nixpkgs.lib.attrsets.listToAttrs (map mkMachine machineFiles));
  };
}
