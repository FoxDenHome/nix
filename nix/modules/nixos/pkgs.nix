{ nixpkgs, systemArch, flakeInputs, ... } :
let
  internalPackages = {
    "nixpkgs" = true;
    "nixpkgs-unstable" = true;
    "impermanence" = true;
    "lanzaboote" = true;
    "sops-nix" = true;
    "self" = true;
  };

  inputsWithoutInternal = nixpkgs.lib.filterAttrs (name: value: let
                              valType = if nixpkgs.lib.isAttrs value then (value._type or null) else null;
                            in
                              valType == "flake" &&
                              !(internalPackages.${name} or false)) flakeInputs;

  removeDefaultPackage = nixpkgs.lib.filterAttrs (name: value: name != "default");
  addPackage = (mod: if (mod.packages or null) != null then removeDefaultPackage mod.packages.${systemArch} else {});

  nixPkgConfig = {
    allowUnfree = true;
  };
in
{
  imports = [
    nixpkgs.nixosModules.readOnlyPkgs
  ];

  config.nixpkgs.pkgs = nixpkgs.lib.mergeAttrsList ([
    (import nixpkgs {
      system = systemArch;
      config = nixPkgConfig;
    })
    {
      config = nixPkgConfig;
    }
  ] ++ (map addPackage (nixpkgs.lib.attrValues inputsWithoutInternal)));
}
