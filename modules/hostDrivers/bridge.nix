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
      (map (({ name, value }: let
        hostSuffix = mkHostSuffix value;
      in
      {
        name = "60-host-${name}";
        value = {
          netdevConfig = {
              Name = "veth-${hostSuffix}";
              Kind = "veth";
          };
          peerConfig = {
              Name = "vpeer-${hostSuffix}";
          };
        };
      })) (nixpkgs.lib.attrsets.attrsToList hosts)));

  networks = (mkBaseNetwork: hosts:
    nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: let
          hostSuffix = mkHostSuffix value;
        in
        [
          {
            name = "60-host-${name}";
            value = nixpkgs.lib.mergeAttrs {
              name = "veth-${hostSuffix}";
              bridge = [driverOpts.bridge];
              bridgeVLANs = [{
                PVID = value.vlan;
                EgressUntagged = value.vlan;
                VLAN = value.vlan;
              }];
            } (mkBaseNetwork name value);
          }
          {
            name = "60-peer-${name}";
            value = {
              name = "vpeer-${hostSuffix}";
            };
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts))));

  infos = (hosts:
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: let
        hostSuffix = mkHostSuffix value;
      in
      {
        hostInterface = "veth-${hostSuffix}";
        serviceInterface = "vpeer-${hostSuffix}";
      }) hosts);
}
