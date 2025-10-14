{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = (interface: "vert-${interface.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    network = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { interfaces, ... } :
  {
    config.systemd.network.networks = nixpkgs.lib.mkMerge (
        (map (iface: {
          "${iface.driverOpts.network}" = {
            networkConfig = {
              IPv4Forwarding = true;
              IPv6Forwarding = true;
            };
          };
        }) interfaces) ++
        [
          (nixpkgs.lib.attrsets.listToAttrs
          (map (iface: {
              name = "60-vert-${iface.host.name}-${iface.name}";
              value = {
                name = mkIfaceName iface;
                networkConfig = {
                  DHCP = "no";
                  IPv6AcceptRA = false;
                  LinkLocalAddressing = "no";
                  IPv4Forwarding = true;
                  IPv6Forwarding = true;
                };
                routes = map (addr: {
                  Destination = addr;
                }) iface.addresses;
              };
            }) interfaces))
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
