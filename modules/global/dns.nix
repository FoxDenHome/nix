{ nixpkgs, ... }:
let
  globalConfig = import ./config.nix { inherit nixpkgs; };

  defaultTtl = 3600;
  dynDnsTtl = 5;

  dnsRecordType = with nixpkgs.lib.types; submodule {
    options = {
      zone = nixpkgs.lib.mkOption {
        type = str;
      };
      name = nixpkgs.lib.mkOption {
        type = str;
      };
      type = nixpkgs.lib.mkOption {
        type = str;
      };
      value = nixpkgs.lib.mkOption {
        type = str;
      };
      ttl = nixpkgs.lib.mkOption {
        type = int;
        default = defaultTtl;
      };
      horizon = nixpkgs.lib.mkOption {
        type = str;
      };
    };
  };
in
{
  defaultTtl = defaultTtl;
  dynDnsTtl = dynDnsTtl;

  nixosModule = { lib, ... }:
  {
    options.foxDen.dns.records = with lib.types; lib.mkOption {
      type = listOf dnsRecordType;
      default = [];
    };
  };

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
