{ nixpkgs, foxDenLib, ... } :
let
  util = foxDenLib.util;
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkIfaceName = (host: "vethrt${host.suffix}");
in
{
  driverOptsType = with nixpkgs.lib.types; submodule { };

  build = { ifcfg, config, hosts, ... } :
  let
    routeHostAddrs = (map (addr: {
      Destination = (util.addHostCidr addr);
    }) ifcfg.addresses);

    mkFirstGw = (predicate: gw: let
      addr = nixpkgs.lib.lists.findFirst predicate "" ifcfg.addresses;
    in if addr != "" then [{ Destination = (util.addHostCidr addr); Gateway = gw; }] else []);
  in
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
              (map (host: host.addresses) hosts)));
        };
      };
    } // (nixpkgs.lib.attrsets.listToAttrs
        (map ((host: {
            name = "60-host-${host.name}";
            value = {
              name = mkIfaceName host;
              networkConfig = {
                DHCP = "no";
                IPv6AcceptRA = "no";
                LinkLocalAddressing = "no";
                IPv4Forwarding = true;
                IPv6Forwarding = true;
              };
              routes = map (addr: {
                Destination = addr;
              }) host.addresses;
            };
          })) hosts));

    execStart = ({ ipCmd, host, serviceInterface, ... }: let
      hostIface = mkIfaceName host;
    in [
      "-${ipCmd} link del ${eSA hostIface}"
      "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
    ]);

    execStop = ({ ipCmd, host, ... }: [
      "${ipCmd} link del ${eSA (mkIfaceName host)}"
    ]);

    routes = routeHostAddrs ++ (nixpkgs.lib.flatten [
      (mkFirstGw util.isIPv4 "0.0.0.0/0")
      (mkFirstGw util.isIPv6 "::/0")
    ]);
  };
}
