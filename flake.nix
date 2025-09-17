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
          relPath = nixpkgs.lib.strings.removePrefix (toString ./. + "/") (toString path);
          components = nixpkgs.lib.path.subpath.components (relPath);

          hostname = nixpkgs.lib.strings.removeSuffix ".nix" (nixpkgs.lib.lists.elemAt components 2); # e.g. bengalfox;
          system = nixpkgs.lib.lists.elemAt components 1; # e.g. x86_64-linux

          hostnameChars = nixpkgs.lib.strings.stringToCharacters hostname;
          hostIdInt = nixpkgs.lib.strings.charToInt (nixpkgs.lib.strings.elemAt hostnameChars 0) * 16777216 +
                   nixpkgs.lib.strings.charToInt (nixpkgs.lib.strings.elemAt hostnameChars 1) * 65536 +
                   nixpkgs.lib.strings.charToInt (nixpkgs.lib.strings.elemAt hostnameChars 2) * 256 +
                   nixpkgs.lib.strings.charToInt (nixpkgs.lib.strings.elemAt hostnameChars 3);
          hostIdBase = nixpkgs.lib.toHexString hostIdInt;
          hostId = (nixpkgs.lib.strings.replicate ((nixpkgs.lib.strings.stringLength hostIdBase) - 8) "0") + hostIdBase;
      in
      {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ({ ... }: {
              networking.hostName = hostname;
              networking.hostId = hostId;
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
