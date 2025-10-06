{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (iface: "vebr${iface.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    vlan = nixpkgs.lib.mkOption {
      type = ints.positive;
    };
    bridge = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { interfaces, ... } :
  {
    config.systemd.network.networks =
      nixpkgs.lib.attrsets.listToAttrs (
        (map ((iface: let
          vlan = iface.driverOpts.vlan;
        in
        {
          name = "60-vebr-${iface.host.name}-${iface.name}";
          value = {
            name = mkIfaceName iface;
            bridge = [iface.driverOpts.bridge];
            bridgeVLANs = [{
              PVID = vlan;
              EgressUntagged = vlan;
              VLAN = vlan;
            }];
          };
        })) interfaces));
  };

  execStart = ({ ipCmd, interface, serviceInterface, ... }: let
    iface = mkIfaceName interface;
  in [
    "-${ipCmd} link del ${eSA iface}"
    "${ipCmd} link add ${eSA iface} type veth peer name ${eSA serviceInterface}"
  ]);
}
