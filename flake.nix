{
  description = "FoxDen Nix config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { nixpkgs, impermanence, lanzaboote, ... }:
  let
    isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

    loadModuleDir = dir: (map (path: { module = import path; path = path; })
                          (nixpkgs.lib.filter isNixFile
                            (nixpkgs.lib.filesystem.listFilesRecursive dir)));

    getNixosModules = classes: (nixpkgs.lib.lists.flatten
                                  (map (val: nixpkgs.lib.attrsets.attrValues val.module.nixosModules or {})
                                        classes));

    inputNixosModules = [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
    ];

    moduleClasses = loadModuleDir ./modules/nixos;
    systemClasses = loadModuleDir ./systems;

    hosts = import ./modules/hosts.nix { inherit nixpkgs; };

    mkSystemConfig = systemClass: let
      splitPath = nixpkgs.lib.path.splitRoot systemClass.path;
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
            config.networking.hostName = hostname;
            config.nixpkgs.hostPlatform = nixpkgs.lib.mkDefault system;

            options.foxDen.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
              type = (listOf hosts.hostType);
              default = [];
            };
          })
        ]
          ++ inputNixosModules
          ++ getNixosModules (moduleClasses ++ [ systemClass ]);
      };
    };

    nixosConfigurations = (nixpkgs.lib.attrsets.listToAttrs (map mkSystemConfig systemClasses));

    foxDen = nixpkgs.lib.filterAttrs (name: val: val != null)
              (nixpkgs.lib.attrsets.mapAttrs (name: val: val.config.foxDen or null) nixosConfigurations);
    foxDenHosts = nixpkgs.lib.lists.flatten (nixpkgs.lib.attrsets.attrValues (nixpkgs.lib.attrsets.mapAttrs (name: val: val.hosts or []) foxDen));
  in
  {
    nixosConfigurations = nixosConfigurations;
    foxDen = foxDen;

    dnsRecords.internal = nixpkgs.lib.attrsets.listToAttrs (map (root: {name = root; value = hosts.mkDnsRecordsOutput root "internal" foxDenHosts; }) hosts.allRoots);
    dnsRecords.external = nixpkgs.lib.attrsets.listToAttrs (map (root: {name = root; value = hosts.mkDnsRecordsOutput root "external" foxDenHosts; }) hosts.allRoots);
  };
}
