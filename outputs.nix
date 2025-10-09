inputs@{ nixpkgs, ... }:
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

    hostName = nixpkgs.lib.strings.removeSuffix ".nix"
                (nixpkgs.lib.strings.elemAt components (componentsLength - 1)); # e.g. bengalfox
    systemArch = nixpkgs.lib.strings.elemAt components (componentsLength - 2); # e.g. x86_64-linux
  in
  {
    name = hostName;
    value = nixpkgs.lib.nixosSystem {
      specialArgs = allLibs // { inherit systemArch hostName; };
      modules = [
        ({ ... }: {
          config.networking.hostName = hostName;
          config.sops.defaultSopsFile = ./secrets/${hostName}.yaml;
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
  dnsRecordsObj = dnsRecords;
  dnsRecords = builtins.toFile "dns-records.json" (builtins.toJSON dnsRecords);

  internalZone = mkZoneFile dnsRecords.internal."foxden.network";
  inputs = inputs;
}
