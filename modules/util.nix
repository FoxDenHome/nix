{ ... }:
let
  mkShortHash = (len: str:
    builtins.substring 0 len (builtins.hashString "sha256" str));

  mkAddrNwInterfaceConfig = cfg: if (cfg.address or null) == null then {} else {
    addresses = [
      {
        address = cfg.address;
        prefixLength = cfg.prefixLength;
      }
    ];
    routes = if (cfg.gateway or null) != null then [
      {
        address = "default";
        prefixLength = 0;
        via = cfg.gateway;
      }
    ] else [];
  };
in
{
  mkShortHash = mkShortHash;
  mkHash8 = mkShortHash 8;

  mkNwInterfaceConfig = (ifcfg: {
    ipv4 = mkAddrNwInterfaceConfig ifcfg.ipv4;
    ipv6 = mkAddrNwInterfaceConfig ifcfg.ipv6;
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
