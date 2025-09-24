{
  description = "FoxDen Nix config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, sops-nix, impermanence, lanzaboote, ... }:
  let
    isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

    mkModuleList = (dir: (nixpkgs.lib.filter isNixFile
                          (nixpkgs.lib.filesystem.listFilesRecursive dir)));

    mkModuleAttrSet = (dir: nixpkgs.lib.attrsets.listToAttrs
                          (map (path: { name = nixpkgs.lib.strings.removeSuffix ".nix" (nixpkgs.lib.path.baseName path); value = path; })
                               (mkModuleList dir)));

    dns = import ./modules/global/dns.nix { inherit nixpkgs; };

    inputNixosModules = [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
      sops-nix.nixosModules.sops
    ];

    modules = mkModuleList ./modules/nixos;
    libs = mkModuleList ./modules/lib;
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
            networking.hostName = hostname;
            nixpkgs.hostPlatform = systemArch;
            sops.defaultSopsFile = ./secrets/${hostname}.yaml;
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
