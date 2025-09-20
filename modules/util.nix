{ nixpkgs, ... }:
let
  mkShortHash = (len: str:
    builtins.substring 0 len (builtins.hashString "sha256" str));

  mkNetworkdRoutes = (ifcfg: (if (ifcfg.ipv4.gateway or "") != "" then [
    {
      Destination = "0.0.0.0/0";
      Gateway = ifcfg.ipv4.gateway;
    }
  ] else []) ++ (if (ifcfg.ipv6.gateway or "") != "" then [
    {
      Destination = "::/0";
      Gateway = ifcfg.ipv6.gateway;
    }
  ] else []));

  mkNetworkdAddresses = (addrs: 
    map (addr: "${addr.address}/${toString addr.prefixLength}")
    (nixpkgs.lib.lists.filter (addr: addr != "") addrs));
in
{
  mkShortHash = mkShortHash;
  mkHash8 = mkShortHash 8;

  mkNetworkdAddresses = mkNetworkdAddresses;
  mkNwInterfaceConfig = (name: ifcfg: {
    name = name;
    routes = mkNetworkdRoutes ifcfg;
    address = mkNetworkdAddresses [ifcfg.ipv4 ifcfg.ipv6];
  });

  mkRoutes = (ifcfg: (if ifcfg.ipv4.gateway != null then [
    {
      gateway = ifcfg.ipv4.gateway;
    }
  ] else []) ++ (if ifcfg.ipv6.gateway != null then [
    {
      gateway = ifcfg.ipv6.gateway;
    }
  ] else []));

  mkSubnet = (ifcfg: {
    ipv4 = ifcfg.ipv4.prefixLength;
    ipv6 = ifcfg.ipv6.prefixLength;
  });
}
