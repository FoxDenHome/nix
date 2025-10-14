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

  systemModules = mkModuleList ./systems;
  systemInfos = map (path: let
    relPath = mkRelPath ./systems path;
    splitPath = nixpkgs.lib.strings.splitString "/" relPath;
  in rec {
    system = builtins.elemAt splitPath 0;
    name = builtins.elemAt splitPath 1;
    path = "${system}/${name}/";
  }) systemModules;

  systems = map (info: {
    inherit (info) name system;
    modules = nixpkgs.lib.filter
      (mod: let
        relPath = mkRelPath ./systems mod;
      in
        nixpkgs.lib.strings.hasPrefix info.path relPath)
      systemModules;
  }) systemInfos;

  mkSystemConfig = system: {
    name = system.name;
    value = nixpkgs.lib.nixosSystem {
      specialArgs = allLibs // {
        systemArch = system.system;
        systemName = system.name;
      };
      modules = [
        ({ ... }: {
          config.networking.hostName = system.name;
          config.sops.defaultSopsFile = ./secrets/${system.name}.yaml;
        })
      ] ++ system.modules ++ modules;
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

  n = systemInfos;
  s = systems;

  dnsRecords = {
    attrset = dnsRecords;
    json = builtins.toFile "dns-records.json" (builtins.toJSON dnsRecords);
  };

  internalZone = mkZoneFile dnsRecords.internal."foxden.network";
  inputs = inputs;
}
