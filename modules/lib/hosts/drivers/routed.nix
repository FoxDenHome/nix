{ nixpkgs, foxDenLib, ... } :
let
  util = foxDenLib.util;
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (interface: "vert${interface.suffix}");

  routeHostAddrs = (ifcfg: (map (addr: {
    Destination = (util.addHostCidr addr);
  }) ifcfg.addresses));

  mkFirstGw = (ifcfg: predicate: gw: let
    addr = nixpkgs.lib.lists.findFirst predicate null ifcfg.addresses;
  in if addr != null then [{ Destination = (util.addHostCidr addr); Gateway = gw; }] else []);
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    network = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { ifcfg, interfaces, ... } :
  {
    config.systemd.network.networks = {
      "${ifcfg.network}" = {
        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;
          IPv4ProxyARP = true;
          IPv6ProxyNDP = true;

          IPv6ProxyNDPAddress = (nixpkgs.lib.filter util.isIPv6
            (nixpkgs.lib.flatten
              (map (iface: iface.addresses) interfaces)));
        };
      };
    } // (nixpkgs.lib.attrsets.listToAttrs
        (map ((iface: {
            name = "60-${iface.host.name}-${iface.name}";
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
          })) interfaces));
  };

  execStart = ({ ipCmd, interface, serviceInterface, ... }: let
    hostIface = mkIfaceName interface;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
  ]);

  execStop = ({ ipCmd, interface, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName interface)}"
  ]);

  routes = ({ config, ... }: let
    ifcfg = config.foxDen.hosts.ifcfg;
  in (routeHostAddrs ifcfg) ++ (nixpkgs.lib.flatten [
    (mkFirstGw ifcfg util.isIPv4 "0.0.0.0/0")
    (mkFirstGw ifcfg util.isIPv6 "::/0")
  ]));
}
