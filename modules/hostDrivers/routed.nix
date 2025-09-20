{ nixpkgs, ifcfg, hosts, mkRoutesAK, ... } :
let
  util = import ../util.nix { inherit nixpkgs; };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "rveth-${mkHostSuffix host}";

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
  configType = with nixpkgs.lib.types; submodule {
  };

  config.systemd.network.networks = nixpkgs.lib.attrsets.mergeAttrs {
    "${ifcfg.network}" = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;
      IPv4ProxyARP = true;
      IPv6ProxyNDP = true;

      IPv6ProxyNDPAddress = (nixpkgs.lib.filter (addr: addr != "")
        (nixpkgs.lib.flatten
          (map
            (host: if host.manageNetwork then [host.external.ipv6 host.internal.ipv6] else [])
            (nixpkgs.lib.attrsets.attrValues hosts))));
    };
  } (nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: let
          allAddrs = (nixpkgs.lib.lists.filter (val: val != "") [
            value.internal.ipv4
            value.internal.ipv6
            value.external.ipv4
            value.external.ipv6
          ]);
          in
          [
          {
            name = "60-host-${name}";
            value.name = (mkIfaceName value);
            value.networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = "no";
              LinkLocalAddressing = "no";
              IPv4Forwarding = true;
              IPv6Forwarding = true;
            };
            value.routes = map (addr: {
              Destination = addr;
            }) allAddrs;
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts))));

  execStart = ({ ipCmd, host, info, ... }: let
    hostIface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStop = ({ ipCmd, host, info, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  routes = routesGWSubnet ++ (mkRoutesAK ifcfg "address");
  subnet = {
    ipv4 = 32;
    ipv6 = 128;
  };

  info =
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts;
}
