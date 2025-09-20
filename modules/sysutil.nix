{ nixpkgs, config, ... }:
let
  driver = config.foxDen.hosts.driver;

  isRouted = driver == "routed";

  mkRoutes = (ifcfg: let
    addrKey = if isRouted then "address" else "gateway";
    addr.ipv4 = ifcfg.ipv4.${addrKey} or "";
    addr.ipv6 = ifcfg.ipv6.${addrKey} or "";
  in(if (addr.ipv4 or "") != "" then [
    {
      Destination = "0.0.0.0/0";
      Gateway = addr.ipv4;
    }
  ] else []) ++ (if (addr.ipv6 or "") != "" then [
    {
      Destination = "::/0";
      Gateway = addr.ipv6;
    }
  ] else []));

  mkNetworkdAddresses = (addrs: 
    map (addr: "${addr.address}/${toString addr.prefixLength}")
    (nixpkgs.lib.lists.filter (addr: addr != "") addrs));
in
{
  mkRoutes = mkRoutes;

  mkNetworkConfig = (name: ifcfg: {
    name = name;
    routes = mkRoutes ifcfg;
    address = mkNetworkdAddresses [ifcfg.ipv4 ifcfg.ipv6];
    dns = ifcfg.dns or [];

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;

      IPv4Forwarding = isRouted;
      IPv6Forwarding = isRouted;
      IPv4ProxyARP = isRouted;
      IPv6ProxyNDP = isRouted;

      IPv6ProxyNDPAddress = nixpkgs.lib.mkIf isRouted
        (nixpkgs.lib.filter (addr: addr != "")
          (nixpkgs.lib.flatten
            (map
              (host: if host.manageNetwork then [host.external.ipv6 host.internal.ipv6] else [])
              (nixpkgs.lib.attrsets.attrValues config.foxDen.hosts.hosts))));
    };
  });

  mkSubnet = (ifcfg: {
    ipv4 = ifcfg.ipv4.prefixLength;
    ipv6 = ifcfg.ipv6.prefixLength;
  });
}
