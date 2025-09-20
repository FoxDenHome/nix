{ ... }:
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

  mkNetworkdAddresses = (ifcfg: (if (ifcfg.ipv4.address or "") != "" then [
    "${ifcfg.ipv4.address}/${toString ifcfg.ipv4.prefixLength}"
  ] else []) ++ (if (ifcfg.ipv6.address or "") != "" then [
    "${ifcfg.ipv6.address}/${toString ifcfg.ipv6.prefixLength}"
  ] else []));
in
{
  mkShortHash = mkShortHash;
  mkHash8 = mkShortHash 8;

  mkNwInterfaceConfig = (name: ifcfg: {
    name = name;
    routes = mkNetworkdRoutes ifcfg;
    address = mkNetworkdAddresses ifcfg;
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
