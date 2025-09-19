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

  execStartLate = ({ ipCmd, ipInNsCmd, host, info, ... }: let
    hostIface = mkIfaceName host;
  in [
    "${ipCmd} addr add 169.254.111.111/16 dev ${eSA hostIface}"
    "${ipCmd} addr add fe80::aaaa/64 dev ${eSA hostIface}"
    "${ipInNsCmd} addr add 169.254.222.222/16 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} addr add fe80::bbbb/64 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} route add default via 169.254.111.111"
    "${ipInNsCmd} route add default via fe80::aaaa"
  ]);

  execStop = ({ ipCmd, host, info, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  infos = (hosts:
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts);
}
