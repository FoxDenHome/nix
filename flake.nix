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

    inputNixosModules = [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
    ];

    modules = mkModuleList ./modules/nixos;
    systems = mkModuleList ./systems;

    dns = import ./modules/dns.nix { inherit nixpkgs; };

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
        modules = [
          ({ ... }: {
            config.networking.hostName = hostname;
            config.nixpkgs.hostPlatform = nixpkgs.lib.mkDefault systemArch;

            options.foxDen.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
              type = (listOf dns.hostType);
              default = [];
            };
          })
        ]
          ++ inputNixosModules
          ++ modules ++ [ system ];
      };
    };
    nixosConfigurations = (nixpkgs.lib.attrsets.listToAttrs (map mkSystemConfig systems));

    foxDen = nixpkgs.lib.filterAttrs (name: val: val != null)
              (nixpkgs.lib.attrsets.mapAttrs (name: val: val.config.foxDen or null) nixosConfigurations);
    foxDenHosts = nixpkgs.lib.lists.flatten (nixpkgs.lib.attrsets.attrValues (nixpkgs.lib.attrsets.mapAttrs (name: val: val.hosts or []) foxDen));
  in
  {
    nixosConfigurations = nixosConfigurations;
    foxDen = foxDen;

    dnsRecords = dns.mkDnsRecordsOutput foxDenHosts;
  };
}
