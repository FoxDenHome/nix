{ ... }:
let
  mkShortHash = (len: str:
    builtins.substring 0 len (builtins.hashString "sha256" str));

  mkAddrNwInterfaceConfig = (defgw: cfg: if (cfg.address or "") == "" then {} else {
    addresses = [
      {
        address = cfg.address;
        prefixLength = cfg.prefixLength;
      }
    ];
    routes = if (cfg.gateway or "") != "" then [
      {
        address = defgw;
        prefixLength = 0;
        via = cfg.gateway;
      }
    ] else [];
  });

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
    {
      Address = "${ifcfg.ipv4.address}/${ifcfg.ipv4.prefixLength}";
    }
  ] else []) ++ (if (ifcfg.ipv6.address or "") != "" then [
    {
      Address = "${ifcfg.ipv6.address}/${ifcfg.ipv6.prefixLength}";
    }
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
