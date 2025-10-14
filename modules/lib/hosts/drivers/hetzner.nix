{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (iface: "vehz-${iface.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    network = nixpkgs.lib.mkOption {
      type = str;
    };
    bridge = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { interfaces, ... } :
  {
    config.systemd.network.networks = nixpkgs.lib.mkMerge (
        (map (iface: {
          "${iface.driverOpts.network}" = {
            networkConfig = {
              IPv6Forwarding = true;
            };
          };
        }) interfaces) ++
        [
          (nixpkgs.lib.attrsets.listToAttrs (
            (map ((iface: {
              name = "60-vehz-${iface.host.name}-${iface.name}";
              value = {
                name = mkIfaceName iface;
                bridge = [iface.driverOpts.bridge];
              };
            })) interfaces)))
        ]);
  };

  hooks = ({ ipCmd, interface, serviceInterface, ... }: let
    hostIface = mkIfaceName interface;
  in
  {
    start = [
      "-${ipCmd} link del ${eSA hostIface}"
      "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
    ];
    stop = [
      "-${ipCmd} link del ${eSA hostIface}"
    ];
  });
}
