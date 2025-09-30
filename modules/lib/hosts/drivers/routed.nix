{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = (interface: "vert${interface.suffix}");
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
              IPv4ProxyARP = true;
              IPv6ProxyNDP = true;

              IPv6ProxyNDPAddress = iface.addresses;
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
                  IPv6AcceptRA = "no";
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

  execStart = ({ ipCmd, interface, serviceInterface, ... }: let
    hostIface = mkIfaceName interface;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
  ]);
}
