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
in
{
  #imports = [
  #  nixpkgs.nixosModules.readOnlyPkgs
  #];
  #config.nixpkgs.pkgs = nixpkgs.legacyPackages.${systemArch};

  config.nixpkgs.hostPlatform = systemArch;
  config.nixpkgs.overlays = map
                              (mod: final: prev:
                                if (mod.packages or null) != null then
                                  removeDefaultPackage mod.packages.${systemArch}
                                else
                                  {})
                              (nixpkgs.lib.attrValues inputsWithoutInternal);
}
