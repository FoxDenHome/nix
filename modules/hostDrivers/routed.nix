{ nixpkgs, ... } :
let
  util = import ../util.nix { };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "rveth-${mkHostSuffix host}";
in
{
  configType = with nixpkgs.lib.types; submodule {
  };

  networks = (hosts:
    nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: [
          {
            name = "60-host-${name}";
            value = {
              name = mkIfaceName value;
            };
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts))));

  execStart = ({ ipCmd, host, info, ... }: let
    hostIface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStartLate = ({ ipCmd, ipInNsCmd, addresses, host, info, ... }: let
    hostIface = mkIfaceName host;
  in [
    "${ipCmd} addr add 169.254.13.37/16 dev ${eSA hostIface}"
    "${ipCmd} addr add fe80::e621/64 dev ${eSA hostIface}"
    "${ipInNsCmd} route add 169.254.13.37 dev ${eSA info.serviceInterface}"
    #"${ipInNsCmd} route add fe80::e621 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} route add default via 169.254.13.37 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} route add default via fe80::e621 dev ${eSA info.serviceInterface}"
  ] ++ (map (addr: "${ipCmd} route add ${eSA addr} dev ${eSA hostIface}") (nixpkgs.lib.lists.filter (val: val != "") [
    host.internal.ipv4
    host.internal.ipv6
    host.external.ipv4
    host.external.ipv6
  ])));

  execStop = ({ ipCmd, host, info, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  infos = (hosts:
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts);
}
