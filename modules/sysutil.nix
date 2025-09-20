{ nixpkgs, config, ... }:
let
  driver = config.foxDen.hosts.driver;

  isRouted = driver == "routed";

  mkRoutesAK = (addrKey: ifcfg: let
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

  mkRoutesGWSubnet = (ifcfg:
  (if (ifcfg.ipv4.address or "") != "" then [
    {
      Destination = "${ifcfg.ipv4.address}/32";
    }
  ] else []) ++ (if (ifcfg.ipv6.address or "") != "" then [
    {
      Destination = "${ifcfg.ipv6.address}/128";
    }
  ] else []));

  mkNetworkdAddresses = (addrs: 
    map (addr: "${addr.address}/${toString addr.prefixLength}")
    (nixpkgs.lib.lists.filter (addr: addr != "") addrs));
in
{
  mkRoutes = (ifcfg:
    if isRouted then
      ((mkRoutesAK "address" ifcfg))
    else
      (mkRoutesAK "gateway" ifcfg));

  mkNetworkConfig = (name: ifcfg: {
    name = name;
    routes = mkRoutesAK "gateway" ifcfg;
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

  mkSubnet = (ifcfg: if isRouted then {
      ipv4 = 32;
      ipv6 = 128;
    } else {
      ipv4 = ifcfg.ipv4.prefixLength;
      ipv6 = ifcfg.ipv6.prefixLength;
    });
}
