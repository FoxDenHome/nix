{
  description = "FoxDen Nix config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = inputs@{ nixpkgs, ... }:
  let
    isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

    loadModuleDir = dir: (map (path: { module = import path; path = path; })
                          (nixpkgs.lib.filter isNixFile
                            (nixpkgs.lib.filesystem.listFilesRecursive dir)));

    getNixosModules = classes: (nixpkgs.lib.lists.flatten
                                  (map (val: nixpkgs.lib.attrsets.attrValues val.module.nixosModules or {})
                                        classes));

    # Finds things like inputs.impermanence.nixosModules.impermanence
    # Some modules might not contain this, so we filter out the empty strings
    inputNixosModules = nixpkgs.lib.filter (val: val != null)
                          (map (val: nixpkgs.lib.attrsets.attrByPath [ "nixosModules" val.name ] null val.value)
                            (nixpkgs.lib.attrsToList inputs));

    moduleClasses = loadModuleDir ./modules;
    systemClasses = loadModuleDir ./systems;

    allClasses = moduleClasses ++ systemClasses;

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

            options.foxDen.dnsRecords = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
              type = (listOf (submodule {
                options = {
                  name = nixpkgs.lib.mkOption {
                    type = str;
                    default = "";
                  };
                  type = nixpkgs.lib.mkOption {
                    type = enum [ "A" "AAAA" "CNAME" "TXT" "MX" "SRV" "PTR" ];
                  };
                  value = nixpkgs.lib.mkOption {
                    type = str;
                    default = "";
                  };
                };
              }));
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
  in
  {
    nixosConfigurations = nixosConfigurations;
    foxDen = foxDen;
    dnsRecords = nixpkgs.lib.lists.flatten
                  (map (val: val.dnsRecords or [])
                    (nixpkgs.lib.attrsets.attrValues foxDen));
  };
}
