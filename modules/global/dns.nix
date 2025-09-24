{ nixpkgs, ... }:
let
  globalConfig = import ./config.nix { inherit nixpkgs; };

  defaultTtl = 3600;
  dynDnsTtl = 5;
in
{
  defaultTtl = defaultTtl;
  dynDnsTtl = dynDnsTtl;

  mkRecords = (nixosConfigurations: let
    records = (globalConfig.getList ["foxDen" "dns" "records"] nixosConfigurations);
    horizons = nixpkgs.lib.lists.uniqueStrings (map (record: record.horizon) records);
    zones = nixpkgs.lib.lists.uniqueStrings (map (record: record.zone) records);
  in
  (nixpkgs.lib.attrsets.genAttrs horizons (horizon:
    nixpkgs.lib.attrsets.genAttrs zones (zone:
      nixpkgs.lib.filter (record: record.horizon == horizon && record.zone == zone) records
    )
  )));
}
