{ nixpkgs, driverOpts, hosts, ... } :
let
  util = import ../util.nix { inherit nixpkgs; };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkIfaceName = host: "veth-${mkHostSuffix host}";
in
{
  configType = with nixpkgs.lib.types; submodule {
    options.bridge = nixpkgs.lib.mkOption {
      type = str;
      default = "br-default";
    };
  };

  config.systemd.network.networks =
    nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: [
          {
            name = "60-host-${name}";
            value = {
              name = mkIfaceName value;
              bridge = [driverOpts.bridge];
              bridgeVLANs = [{
                PVID = value.vlan;
                EgressUntagged = value.vlan;
                VLAN = value.vlan;
              }];
            };
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts)));

  execStart = ({ ipCmd, host, info, ... }: let
    iface = mkIfaceName host;
  in [
    "-${ipCmd} link del ${eSA iface}"
    "${ipCmd} link add ${eSA iface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStop = ({ ipCmd, host, info, ... }: [
    "${ipCmd} link del ${eSA (mkIfaceName host)}"
  ]);

  execStartLate = ({ ... }: []);

  info =
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: {
        serviceInterface = "pveth-${mkHostSuffix value}";
      }) hosts;
}
