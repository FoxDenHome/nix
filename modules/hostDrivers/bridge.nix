{ nixpkgs, ... } :
let
  util = import ../util.nix { };
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
      (map ((val: let
        hostSuffix = util.mkHash8 val.name;
      in
      {
        name = "60-host-${val.name}";
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
      (map ((val: let
        hostSuffix = util.mkHash8 val.name;
        host = val.value;
      in
      {
        name = "60-veth-${val.name}";
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
