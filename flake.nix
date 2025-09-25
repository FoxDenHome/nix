{
  description = "FoxDen NixOS config";

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

    mkRelPath = (root: path: nixpkgs.lib.strings.removePrefix (builtins.toString root+"/") (builtins.toString path));

    mkModuleList = (dir: (nixpkgs.lib.filter isNixFile
                          (nixpkgs.lib.filesystem.listFilesRecursive dir)));

    modParams = { inherit nixpkgs; inherit foxDenLib; };

    tryEvalOrEmpty = (val: let
      eval = (builtins.tryEval val);
    in if eval.success then eval.value else {});

    mkModuleAttrSet = (dir: let
                        loadedMods = map (path: {
                          name = nixpkgs.lib.strings.removeSuffix ".nix" (mkRelPath dir path);
                          value = import path modParams;
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

    modules = (mkModuleList ./modules/nixos) ++ [
      impermanence.nixosModules.impermanence
      lanzaboote.nixosModules.lanzaboote
      sops-nix.nixosModules.sops
    ] ++ (nixpkgs.lib.filter (mod: mod != null)
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
        system = systemArch;
        specialArgs = { inherit nixpkgs; inherit foxDenLib; };
        modules = [
          ({ ... }: {
            networking.hostName = hostname;
            nixpkgs.hostPlatform = systemArch;
            sops.defaultSopsFile = ./secrets/${hostname}.yaml;
          })
          system
        ] ++ modules;
      };
    };
    nixosConfigurations = (nixpkgs.lib.attrsets.listToAttrs (map mkSystemConfig systems));
  in
  {
    nixosConfigurations = nixosConfigurations;
    dnsRecords = (foxDenLib.global.dns.mkRecords nixosConfigurations);
  };
}
