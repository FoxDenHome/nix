{ nixpkgs, ... }:
let
  globalConfig = import ./globalConfig.nix { inherit nixpkgs; };

  allHorizons = [ "internal" "external" ];

  defaultTtl = 3600;
  dynDnsTtl = 5;

  hostDnsRecordType = with nixpkgs.lib.types; submodule {
    options = {
      type = nixpkgs.lib.mkOption {
        type = str;
        default = "A";
      };
      value = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      ttl = nixpkgs.lib.mkOption {
        type = int;
        default = defaultTtl;
      };
    };
  };

  hostHorizonConfigType = with nixpkgs.lib.types; submodule {
    options = {
      ipTtl = nixpkgs.lib.mkOption {
        type = int;
        default = defaultTtl;
      };
      ipv4 = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      ipv6 = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      records = nixpkgs.lib.mkOption {
        type = listOf hostDnsRecordType;
        default = [];
      };
    };
  };

  hostType = with nixpkgs.lib.types; submodule {
    options = (nixpkgs.lib.mergeAttrs
      {
        name = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        root = nixpkgs.lib.mkOption {
          type = str;
          default = "foxden.network";
        };
      }
      (nixpkgs.lib.attrsets.listToAttrs (map (horizon: {
        name = horizon;
        value = nixpkgs.lib.mkOption {
          type = hostHorizonConfigType;
          default = {};
        };
      }) allHorizons))
    );
  };

  mkDnsRecordsOutputHost = (root: horizon: host: let
      hostAddress = host.${horizon};
      dynDnsV4 = hostAddress.ipv4 == "dyn";
      dynDnsV6 = hostAddress.ipv6 == "dyn";
    in if root == host.root then [
      {
        name = host.name;
        type = "A";
        value = if dynDnsV4 then "127.0.0.1" else hostAddress.ipv4;
        ttl = if dynDnsV4 then dynDnsTtl else hostAddress.ipTtl;
        dynDns = dynDnsV4;
      }
      {
        name = host.name;
        type = "AAAA";
        value = if dynDnsV6 then "fe80::1" else hostAddress.ipv6;
        ttl = if dynDnsV6 then dynDnsTtl else hostAddress.ipTtl;
        dynDns = dynDnsV6;
      }
    ] ++
      map (record: {
        name = host.name;
        type = record.type;
        value = record.value;
        ttl = record.ttl;
        dynDns = false;
      }) (hostAddress.records or [])
    else []
  );

  mkDnsRecordsOutputRoot = (root: horizon: hosts: 
      nixpkgs.lib.filter (record: record.value != "")
        (nixpkgs.lib.lists.flatten
          (map (mkDnsRecordsOutputHost root horizon) hosts)));

  mkDnsRecordsOutputAddrType = (horizon: hosts: roots:
    nixpkgs.lib.attrsets.listToAttrs
      (map (root: {name = root; value = mkDnsRecordsOutputRoot root horizon hosts; })
        roots));

in
{
  hostType = hostType;
  hostHorizonConfigType = hostHorizonConfigType;
  hostDnsRecordType = hostDnsRecordType;

  mkHostOption = with nixpkgs.lib.types; (opts : nixpkgs.lib.mkOption (nixpkgs.lib.mergeAttrs {
    type = if opts.default == null then (nullOr hostType) else hostType;
  } opts));

  mkRecords = (nixosConfigurations: let
      allHosts = nixpkgs.lib.filter (val: val != null)
      (globalConfig.getList ["dns" "hosts"] nixosConfigurations);
      roots = nixpkgs.lib.lists.uniqueStrings (map (host: host.root) allHosts);
    in
    nixpkgs.lib.attrsets.listToAttrs
      (map (horizon: {name = horizon; value = mkDnsRecordsOutputAddrType horizon allHosts roots; })
        allHorizons));

  nixosModules.dns = ({ ... }: {
    options.dns.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (listOf (nullOr hostType));
      default = [];
    };
  });
}
