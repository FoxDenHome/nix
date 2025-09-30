{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (iface: "vebr${iface.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    vlan = nixpkgs.lib.mkOption {
      type = ints.unsigned;
      default = 0;
    };
    bridge = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { interfaces, ... } :
  {
    config.systemd.network.networks =
      nixpkgs.lib.attrsets.listToAttrs (
        nixpkgs.lib.lists.flatten
          (map ((iface: let
            vlan = iface.driverOpts.vlan or 0;
          in [
            {
              name = "60-vebr-${iface.host.name}-${iface.name}";
              value = {
                name = mkIfaceName iface;
                bridge = [iface.driverOpts.bridge];
                bridgeVLANs = if (vlan > 0) then [{
                  PVID = vlan;
                  EgressUntagged = vlan;
                  VLAN = vlan;
                }] else [];
              };
            }
          ])) interfaces));
  };

  execStart = ({ ipCmd, interface, serviceInterface, ... }: let
    iface = mkIfaceName interface;
  in [
    "-${ipCmd} link del ${eSA iface}"
    "${ipCmd} link add ${eSA iface} type veth peer name ${eSA serviceInterface}"
  ]);
}
