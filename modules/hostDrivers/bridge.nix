{ nixpkgs, driverOpts, ... } :
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

  netDevs = (hosts:
    nixpkgs.lib.attrsets.listToAttrs
      (map ((host: let
        hostSuffix = mkHostSuffix host;
      in
      {
        name = "60-host-${host.name}";
        value = {
          netdevConfig = {
              Name = "veth-${hostSuffix}";
              Kind = "veth";
          };
          peerConfig = {
              Name = "vpeer-${hostSuffix}";
          };
        };
      })) hosts));

  networks = (hosts:
    nixpkgs.lib.attrsets.listToAttrs
      (map ((host: let
        hostSuffix = mkHostSuffix host;
      in
      {
        name = "60-veth-${host.name}";
        value = {
          name = "veth-${hostSuffix}";
          bridge = [driverOpts.bridge];
          bridgeVLANs = [{
            PVID = host.vlan;
            EgressUntagged = host.vlan;
            VLAN = host.vlan;
          }];
        };
      })) hosts));

  info = (host: {
    hostInterface = "veth-${mkHostSuffix host}";
    serviceInterface = "vpeer-${mkHostSuffix host}";
  });
}
