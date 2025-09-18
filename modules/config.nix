{ nixosConfigurations, nixpkgs }:
let
  get = (attrPath: nixpkgs.lib.filterAttrs (name: val: val != null)
          (nixpkgs.lib.attrsets.mapAttrs (name: val: (nixpkgs.lib.attrsets.attrByPath attrPath null val.config)) nixosConfigurations));

  getList = (attrPath: nixpkgs.lib.lists.flatten (nixpkgs.lib.attrsets.attrValues (get attrPath)));
in
{
  get = get;
  getList = getList;

  getAttrSet = (attrPath: nixpkgs.lib.attrsets.mergeAttrsList (getList attrPath));
}
