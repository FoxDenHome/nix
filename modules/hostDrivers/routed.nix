{ nixpkgs, pkgs, ... } :
let
  util = import ../util.nix { };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "rveth-${mkHostSuffix host}";

  ipCmd = eSA "${pkgs.iproute2}/bin/ip";
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

  execStart = (host: info: let
    iface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA iface}"
    "${ipCmd} link add ${eSA iface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStop = (host: info: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  infos = (hosts:
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts);
}
