{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  globalConfig = foxDenLib.global.config;

  defaultTtl = 3600;
  dynDnsTtl = 5;

  dnsRecordType = with lib.types; submodule {
    options = {
      zone = lib.mkOption {
        type = str;
      };
      name = lib.mkOption {
        type = str;
      };
      type = lib.mkOption {
        type = str;
      };
      value = lib.mkOption {
        type = str;
      };
      ttl = lib.mkOption {
        type = ints.positive;
        default = defaultTtl;
      };
      horizon = lib.mkOption {
        type = str;
      };
    };
  };
in
{
  defaultTtl = defaultTtl;
  dynDnsTtl = dynDnsTtl;

  nixosModule = { ... } : {
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
