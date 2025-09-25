{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
in
{
  driverOptsType = with nixpkgs.lib.types; submodule { };

  build = { nixpkgs, ifcfg, mkHostSuffix, hosts, ... } :
  let
    mkIfaceName = name: "vethbr${mkHostSuffix name}";
  in
  {
    config.systemd.network.networks =
      nixpkgs.lib.attrsets.listToAttrs (
        nixpkgs.lib.lists.flatten
          (map (({ name, value }: [
            {
              name = "60-host-${name}";
              value = {
                name = mkIfaceName name;
                bridge = [ifcfg.interface];
                bridgeVLANs = [{
                  PVID = value.vlan;
                  EgressUntagged = value.vlan;
                  VLAN = value.vlan;
                }];
              };
            }
          ])) (nixpkgs.lib.attrsets.attrsToList hosts)));

    config.systemd.network.netdevs.${ifcfg.interface} = {
      netdevConfig = {
        Name = ifcfg.interface;
        Kind = "bridge";
      };

      bridgeConfig = {
        VLANFiltering = true;
      };
    };

    execStart = ({ ipCmd, hostName, serviceInterface, ... }: let
      iface = mkIfaceName hostName;
    in [
      "-${ipCmd} link del ${eSA iface}"
      "${ipCmd} link add ${eSA iface} type veth peer name ${eSA serviceInterface}"
    ]);

    execStop = ({ ipCmd, hostName, ... }: [
      "${ipCmd} link del ${eSA (mkIfaceName hostName)}"
    ]);
  };
}
