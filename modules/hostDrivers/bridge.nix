{ nixpkgs, driverOpts, mkHostSuffix, hosts, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "bveth-${mkHostSuffix host}";
in
{
  configType = with nixpkgs.lib.types; submodule {
    options.bridge = nixpkgs.lib.mkOption {
      type = str;
      default = "br-default";
    };
  };

  config.systemd.network.networks =
    nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: [
          {
            name = "60-host-${name}";
            value = {
              name = mkIfaceName value;
              bridge = [driverOpts.bridge];
              bridgeVLANs = [{
                PVID = value.vlan;
                EgressUntagged = value.vlan;
                VLAN = value.vlan;
              }];
            };
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts)));

  config.systemd.network.netdevs.${driverOpts.bridge} = {
    netdevConfig = {
      Name = driverOpts.bridge;
      Kind = "bridge";
    };

    bridgeConfig = {
      VLANFiltering = true;
    };
  };

  execStart = ({ ipCmd, host, serviceInterface, ... }: let
    iface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA iface}"
    "${ipCmd} link add ${eSA iface} type veth peer name ${eSA (serviceInterface)}"
  ]);

  execStop = ({ ipCmd, host, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);
}
