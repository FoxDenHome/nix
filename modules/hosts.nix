{ nixpkgs, ... }:
  let
    hostAddressType = with nixpkgs.lib.types; submodule {
      options = {
        ipv4 = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        ipv6 = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
      };
    };

    allRoots = [ "foxden.network" "doridian.net" ];

    hostType = with nixpkgs.lib.types; submodule {
      options = {
        name = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        root = nixpkgs.lib.mkOption {
          type = enum allRoots;
          default = "foxden.network";
        };
        internal = nixpkgs.lib.mkOption {
          type = hostAddressType;
          default = {};
        };
        external = nixpkgs.lib.mkOption {
          type = hostAddressType;
          default = {};
        };
      };
    };

    mkSuffixedDnsRecords = (root: addressType: host: let
        hostAddress = host.${addressType} or { ipv4 = ""; ipv6 = ""; };
        dynDnsV4 = hostAddress.ipv4 == "dyn";
        dynDnsV6 = hostAddress.ipv6 == "dyn";
      in if root == host.root then [
        {
          name = host.name;
          type = "A";
          value = if dynDnsV4 then "127.0.0.1" else hostAddress.ipv4;
          dynDns = dynDnsV4;
        }
        {
          name = host.name;
          type = "AAAA";
          value = if dynDnsV6 then "fe80::1" else hostAddress.ipv6;
          dynDns = dynDnsV6;
        }
      ] else []
    );

    mkDnsRecordsOutput = (root: addressType: hosts: 
        nixpkgs.lib.filter (record: record.value != "")
          (nixpkgs.lib.lists.flatten
            (map (mkSuffixedDnsRecords root addressType) hosts))
    );
  in
  {
    hostType = hostType;
    allRoots = allRoots;
    hostAddressType = hostAddressType;
    mkDnsRecordsOutput = mkDnsRecordsOutput;
    mkSuffixedDnsRecords = mkSuffixedDnsRecords;
  }
