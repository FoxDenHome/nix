{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };

  allHorizons = [ "internal" "external" ];

  defaultTtl = 3600;
  dynDnsTtl = 5;

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
  defaultTtl = defaultTtl;
  dynDnsTtl = dynDnsTtl;
  allHorizons = allHorizons;

  mkRecords = (nixosConfigurations: let
      allHosts = hosts.allHosts nixosConfigurations;
      roots = nixpkgs.lib.lists.uniqueStrings (map (host: host.root) allHosts);
    in
    nixpkgs.lib.attrsets.listToAttrs
      (map (horizon: {name = horizon; value = mkDnsRecordsOutputAddrType horizon allHosts roots; })
        allHorizons));
}
