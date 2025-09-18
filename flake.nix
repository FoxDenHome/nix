{
  description = "FoxDen Nix config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { nixpkgs, impermanence, lanzaboote, ... }:
  let
    isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

    mkModuleList = dir: (nixpkgs.lib.filter isNixFile
                          (nixpkgs.lib.filesystem.listFilesRecursive dir));

    dns = import ./modules/dns.nix { inherit nixpkgs; };

    inputNixosModules = [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
      dns.nixosModules.dns
    ];

    modules = mkModuleList ./modules/nixos;
    systems = mkModuleList ./systems;

    mkSystemConfig = system: let
      splitPath = nixpkgs.lib.path.splitRoot system;
      components = nixpkgs.lib.path.subpath.components splitPath.subpath;
      componentsLength = nixpkgs.lib.lists.length components;

      hostname = nixpkgs.lib.strings.removeSuffix ".nix"
                  (nixpkgs.lib.strings.elemAt components (componentsLength - 1)); # e.g. bengalfox
      systemArch = nixpkgs.lib.strings.elemAt components (componentsLength - 2); # e.g. x86_64-linux
    in
    {
      name = hostname;
      value = nixpkgs.lib.nixosSystem {
        system = systemArch;
        specialArgs = { inherit nixpkgs; };
        modules = [
          ({ ... }: {
            config.networking.hostName = hostname;
            config.nixpkgs.hostPlatform = nixpkgs.lib.mkDefault systemArch;
          })
          system
        ] ++ inputNixosModules ++ modules;
      };
    };
    nixosConfigurations = (nixpkgs.lib.attrsets.listToAttrs (map mkSystemConfig systems));
  in
  {
    nixosConfigurations = nixosConfigurations;
    dnsRecords = (dns.mkRecords nixosConfigurations);
  };
}
