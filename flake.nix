{
  description = "FoxDen NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    uds-proxy.url = "github:Doridian/uds-proxy";
    uds-proxy.inputs.nixpkgs.follows = "nixpkgs";
    fadumper.url = "github:Doridian/fadumper";
    fadumper.inputs.nixpkgs.follows = "nixpkgs";
    gitbackup.url = "github:Doridian/gitbackup";
    gitbackup.inputs.nixpkgs.follows = "nixpkgs";
    superfan.url = "github:Doridian/superfan";
    superfan.inputs.nixpkgs.follows = "nixpkgs";
    e621dumper.url = "github:FoxDenHome/e621dumper";
    e621dumper.inputs.nixpkgs.follows = "nixpkgs";
    backupmgr.url = "github:FoxDenHome/backupmgr";
    backupmgr.inputs.nixpkgs.follows = "nixpkgs";
    nginx-mirror.url = ./modules/flakes/nginx/mirror;
    nginx-mirror.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, ... }:
  let
    isNixFile = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;

    mkRelPath = (root: path: nixpkgs.lib.strings.removePrefix (builtins.toString root+"/") (builtins.toString path));

    mkModuleList = (dir: (nixpkgs.lib.filter isNixFile
                          (nixpkgs.lib.filesystem.listFilesRecursive dir)));

    allLibs = { inherit foxDenLib; flakeInputs = inputs; } // (nixpkgs.lib.filterAttrs (name: value: name != "self") inputs);

    tryEvalOrEmpty = (val: let
      eval = (builtins.tryEval val);
    in if eval.success then eval.value else {});

    mkModuleAttrSet = (dir: let
                        loadedMods = map (path: let
                          nameRaw = nixpkgs.lib.strings.removeSuffix ".nix" (mkRelPath dir path);
                        in {
                          name = nixpkgs.lib.strings.removeSuffix "/main" nameRaw;
                          value = import path allLibs;
                        }) (mkModuleList dir);
                      in
                      {
                          nested = (nixpkgs.lib.attrsets.updateManyAttrsByPath (map
                            ({ name, value }: {
                                path = (nixpkgs.lib.strings.splitString "/" name);
                                update = old: (tryEvalOrEmpty old) // value;
                            })
                            loadedMods) {});

                          flat = nixpkgs.lib.attrsets.listToAttrs loadedMods;
                      });

    foxDenLibsRaw = mkModuleAttrSet ./modules/lib;
    foxDenLib = foxDenLibsRaw.nested;

    modules = (mkModuleList ./modules/nixos) ++ (nixpkgs.lib.filter (mod: mod != null)
      (map
        (mod: mod.nixosModule or null)
        (nixpkgs.lib.attrsets.attrValues foxDenLibsRaw.flat)
    ));

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
        specialArgs = allLibs // { inherit systemArch; };
        modules = [
          ({ ... }: {
            config.networking.hostName = hostname;
            config.sops.defaultSopsFile = ./secrets/${hostname}.yaml;
          })
          system
        ] ++ modules;
      };
    };
    nixosConfigurations = (nixpkgs.lib.attrsets.listToAttrs (map mkSystemConfig systems));
    dnsRecords = (foxDenLib.global.dns.mkRecords nixosConfigurations);

    mkZoneFile = (records: builtins.toFile "records.db"
                  (nixpkgs.lib.concatLines
                    (map
                      (record: "${record.name} ${builtins.toString record.ttl} IN ${record.type} ${record.value}")
                      records)));
  in
  {
    nixosConfigurations = nixosConfigurations;
    dnsRecords = builtins.toFile "dns-records.json" (builtins.toJSON dnsRecords);

    internalZone = mkZoneFile dnsRecords.internal."foxden.network";
    inputs = inputs;
  };
}
