{ nixpkgs, ifcfg, hosts, mkRoutesAK, mkHostSuffix, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "vethrt${mkHostSuffix host}";

  routesGWSubnet =
    (if (ifcfg.ipv4.address or "") != "" then [
      {
        Destination = "${ifcfg.ipv4.address}/32";
      }
    ] else []) ++ (if (ifcfg.ipv6.address or "") != "" then [
      {
        Destination = "${ifcfg.ipv6.address}/128";
      }
    ] else []);
in
{
  configType = with nixpkgs.lib.types; submodule { };

  config.systemd.network.networks = nixpkgs.lib.mergeAttrs {
    "${ifcfg.network}" = {
      networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
        IPv4ProxyARP = true;
        IPv6ProxyNDP = true;

        IPv6ProxyNDPAddress = (nixpkgs.lib.filter (addr: addr != "")
          (nixpkgs.lib.flatten
            (map
              (host: [host.external.ipv6 host.internal.ipv6])
              hosts)));
      };
    };
  } (nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map ((host: let
          allAddrs = (nixpkgs.lib.lists.filter (val: val != "") [
            value.internal.ipv4
            value.internal.ipv6
            value.external.ipv4
            value.external.ipv6
          ]);
          in
          [
          {
            name = "60-host-${host.name}";
            value = {
              name = (mkIfaceName host);
              networkConfig = {
                DHCP = "no";
                IPv6AcceptRA = "no";
                LinkLocalAddressing = "no";
                IPv4Forwarding = true;
                IPv6Forwarding = true;
              };
              routes = map (addr: {
                Destination = addr;
              }) allAddrs;
            };
          }
        ])) hosts)));

  execStart = ({ ipCmd, host, serviceInterface, ... }: let
    hostIface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA serviceInterface}"
  ]);

  execStop = ({ ipCmd, host, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  routes = routesGWSubnet ++ (mkRoutesAK ifcfg "address");
  subnet = {
    ipv4 = 32;
    ipv6 = 128;
  };
}
