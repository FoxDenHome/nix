{ nixpkgs, hosts, ... } :
let
  util = import ../util.nix { inherit nixpkgs; };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "rveth-${mkHostSuffix host}";
in
{
  configType = with nixpkgs.lib.types; submodule {
  };

  config.systemd.network.networks = nixpkgs.lib.attrsets.listToAttrs (
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
            value.address = util.mkNetworkdAddresses [
              {
                address = "169.254.13.37";
                prefixLength = 16;
              }
              {
                address = "fe80::e621";
                prefixLength = 64;
              }
            ];
            value.routes = map (addr: {
              Destination = addr;
            }) allAddrs;
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts)));

  execStart = ({ ipCmd, host, info, ... }: let
    hostIface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA hostIface}"
    "${ipCmd} link add ${eSA hostIface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStartLate = ({ ipInNsCmd, info, ... }: [
    "${ipInNsCmd} route add 169.254.13.37 dev ${eSA info.serviceInterface}"
    #"${ipInNsCmd} route add fe80::e621 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} route add default via 169.254.13.37 dev ${eSA info.serviceInterface}"
    "${ipInNsCmd} route add default via fe80::e621 dev ${eSA info.serviceInterface}"
  ]);

  execStop = ({ ipCmd, host, info, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  info =
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts;
}
