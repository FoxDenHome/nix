{ nixpkgs, ... } :
let
  util = import ../util.nix { };
  mkHostSuffix = host: util.mkHash8 host.name;
in
{
  configType = with nixpkgs.lib.types; submodule {
    options.bridge = nixpkgs.lib.mkOption {
      type = str;
      default = "br-default";
    };
  };

  netDevs = (opts: (hosts:
    nixpkgs.lib.attrsets.listToAttrs
      (map ((host: let
        hostSuffix = mkHostSuffix host;
      in
      {
        name = "60-veth-${hostSuffix}";
        value = {
          netdevConfig = {
              Name = "veth-${hostSuffix}";
              Kind = "veth";
          };
          peerConfig = {
              Name = "vpeer-${hostSuffix}";
          };
        };
      })) hosts)));

  networks = (opts: (hosts:
    nixpkgs.lib.attrsets.listToAttrs
      (map ((host: let
        hostSuffix = mkHostSuffix host;
      in
      {
        name = "60-veth-${hostSuffix}";
        value = {
          name = "veth-${hostSuffix}";
          bridge = [opts.bridge];
          bridgeVLANs = [{
            PVID = host.vlan;
            EgressUntagged = host.vlan;
            VLAN = host.vlan;
          }];
        };
      })) hosts)));
}
