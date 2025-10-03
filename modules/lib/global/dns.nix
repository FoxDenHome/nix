{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  globalConfig = foxDenLib.global.config;

  defaultTtl = 3600;

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
      dynDns = lib.mkOption {
        type = bool;
        default = false;
      };
      horizon = lib.mkOption {
        type = enum [ "internal" "external" ];
      };
    };
  };
in
{
  defaultTtl = defaultTtl;

  nixosModule = { ... } : {
    options.foxDen.dns.records = with lib.types; lib.mkOption {
      type = listOf dnsRecordType;
      default = [];
    };
  };

  mkHost = (record: if record.name == "@" then record.zone else "${record.name}.${record.zone}");

  mkRecords = (nixosConfigurations: let
    records = globalConfig.getList ["foxDen" "dns" "records"] nixosConfigurations;
    # TODO: Go back to uniqueStrings once next NixOS stable
    horizons = nixpkgs.lib.lists.unique (map (record: record.horizon) records);
    zones = nixpkgs.lib.lists.unique (map (record: record.zone) records);
  in
  (nixpkgs.lib.attrsets.genAttrs horizons (horizon:
    nixpkgs.lib.attrsets.genAttrs zones (zone:
      nixpkgs.lib.filter (record:
        record.horizon == horizon && record.zone == zone)
        records
    )
  )));
}
