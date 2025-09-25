{ nixpkgs, foxDenLib, ... } :
let
  util = foxDenLib.util;
  eSA = nixpkgs.lib.strings.escapeShellArg;
in
{
  driverOptsType = with nixpkgs.lib.types; submodule { };

  build = { ifcfg, hosts, ... } :
  let
    mkIfaceName = (name: let
      host = hosts.getByName name;
    in
      "vethrt${host.info.suffix}");

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
        (map (({ name, value }: {
            name = "60-host-${name}";
            value = {
              name = (mkIfaceName name);
              networkConfig = {
                DHCP = "no";
                IPv6AcceptRA = "no";
                LinkLocalAddressing = "no";
                IPv4Forwarding = true;
                IPv6Forwarding = true;
              };
              routes = map (addr: {
                Destination = addr;
              }) value.addresses;
            };
          })) (nixpkgs.lib.attrsets.attrsToList hosts)));

    execStart = ({ ipCmd, hostName, serviceInterface, ... }: let
      hostIface = mkIfaceName hostName;
    in [
      "-${ipCmd} link del ${eSA hostIface}"
      "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
    ]);

    execStop = ({ ipCmd, hostName, ... }: [
      "${ipCmd} link del ${eSA (mkIfaceName hostName)}"
    ]);

    routes = routeHostAddrs ++ (nixpkgs.lib.flatten [
      (mkFirstGw util.isIPv4 "0.0.0.0/0")
      (mkFirstGw util.isIPv6 "::/0")
    ]);
  };
}
