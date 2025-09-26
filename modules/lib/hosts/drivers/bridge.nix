{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (iface: "vebr${iface.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    vlan = nixpkgs.lib.mkOption {
      type = ints.unsigned;
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
          (map ((iface: [
            {
              name = "60-vebr-${iface.host.name}-${iface.name}";
              value = {
                name = mkIfaceName iface;
                bridge = [iface.driverOpts.interface];
                bridgeVLANs = if (iface.vlan > 0) then [{
                  PVID = iface.vlan;
                  EgressUntagged = iface.vlan;
                  VLAN = iface.vlan;
                }] else [];
              };
            }
          ])) interfaces));

    config.systemd.network.netdevs =
      nixpkgs.lib.attrsets.listToAttrs (
        nixpkgs.lib.lists.flatten
          (map ((iface: [
            {
              name = iface.driverOpts.bridge;
              value = {
                netdevConfig = {
                  Name = iface.driverOpts.bridge;
                  Kind = "bridge";
                };

                bridgeConfig = {
                  VLANFiltering = true;
                };
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

  execStop = ({ ipCmd, interface, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName interface)}"
  ]);
}
