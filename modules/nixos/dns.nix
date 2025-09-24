{ lib, ... }:
let
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
        type = int;
        default = defaultTtl;
      };
      horizon = lib.mkOption {
        type = str;
      };
    };
  };
in
{
  options.foxDen.dns.records = with lib.types; lib.mkOption {
    type = listOf dnsRecordType;
    default = [];
  };
}
