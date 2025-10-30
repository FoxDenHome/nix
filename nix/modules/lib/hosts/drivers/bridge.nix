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
        (map ((iface: let
          vlan = iface.driverOpts.vlan;
        in
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
        })) interfaces));
  };

  hooks = ({ ipCmd, interface, defaultServiceInterface, ... }: let
    hostIface = mkIfaceName interface;
  in
  {
    start = [
      "-${ipCmd} link del ${eSA hostIface}"
      "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA defaultServiceInterface}"
    ];
    stop = [
      "-${ipCmd} link del ${eSA hostIface}"
    ];
  });
}
