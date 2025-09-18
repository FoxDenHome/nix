{ nixpkgs, ... } :
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
        hostSuffix = builtins.substring 0 8 (builtins.hashString "sha256" host.name);
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
      })) hosts));

  networks = (opts: (hosts:
    nixpkgs.lib.attrsets.listToAttrs
      (map ((host: let
        hostSuffix = builtins.substring 0 8 (builtins.hashString "sha256" host.name);
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
