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

    hostAddressType = with nixpkgs.lib.types; submodule {
      options = {
        ipv4 = nixpkgs.lib.mkOption {
          type = str;
          default = "dyn";
        };
        ipv6 = nixpkgs.lib.mkOption {
          type = str;
          default = "dyn";
        };
      };
    };

    hostType = with nixpkgs.lib.types; submodule {
      options = {
        name = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        internal = nixpkgs.lib.mkOption {
          type = hostAddressType;
          default = {};
        };
        external = nixpkgs.lib.mkOption {
          type = hostAddressType;
          default = {};
        };
      };
    };

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
              type = (listOf hostType);
              default = [];
            };

            options.foxDen.dynDns = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
              type = bool;
              default = false;
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

    mkSuffixedDnsRecords = (suffix: addressType: host: let
        hostAddress = host.${addressType} or { ipv4 = ""; ipv6 = ""; };
        name = "${host.name}.${suffix}";
        dynDnsV4 = hostAddress.ipv4 == "dyn";
        dynDnsV6 = hostAddress.ipv6 == "dyn";
      in [
        {
          name = name;
          type = "A";
          value = if dynDnsV4 then "127.0.0.1" else hostAddress.ipv4;
          dynDns = dynDnsV4;
        }
        {
          name = name;
          type = "AAAA";
          value = if dynDnsV6 then "fe80::1" else hostAddress.ipv6;
          dynDns = dynDnsV6;
        }
      ]
    );

    mkDnsRecordsOutput = (suffix: addressType:
        nixpkgs.lib.filter (record: record.value != "")
          (nixpkgs.lib.lists.flatten
            (map
              (info: (map (mkSuffixedDnsRecords suffix addressType) (info.value.hosts or [])))
              (nixpkgs.lib.attrsets.attrsToList foxDen)))
    );
  in
  {
    nixosConfigurations = nixosConfigurations;
    foxDen = foxDen;

    dnsRecords.internal = mkDnsRecordsOutput "foxden.network" "internal";
    dnsRecords.external = mkDnsRecordsOutput "doridian.net" "external";
  };
}
