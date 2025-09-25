{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
in
{
  driverOptsType = with nixpkgs.lib.types; submodule { };

  build = { ifcfg, config, hosts, ... } :
  let
    mkIfaceName = (host: "vethbr${host.suffix}");
  in
  {
    config.systemd.network.networks =
      nixpkgs.lib.attrsets.listToAttrs (
        nixpkgs.lib.lists.flatten
          (map ((host: [
            {
              name = "60-host-${host.name}";
              value = {
                name = mkIfaceName host;
                bridge = [ifcfg.interface];
                bridgeVLANs = [{
                  PVID = host.vlan;
                  EgressUntagged = host.vlan;
                  VLAN = host.vlan;
                }];
              };
            }
          ])) hosts));

    config.systemd.network.netdevs.${ifcfg.interface} = {
      netdevConfig = {
        Name = ifcfg.interface;
        Kind = "bridge";
      };

      bridgeConfig = {
        VLANFiltering = true;
      };
    };

    execStart = ({ ipCmd, host, serviceInterface, ... }: let
      iface = mkIfaceName host;
    in [
      "-${ipCmd} link del ${eSA iface}"
      "${ipCmd} link add ${eSA iface} type veth peer name ${eSA serviceInterface}"
    ]);

    execStop = ({ ipCmd, host, ... }: [
      "${ipCmd} link del ${eSA (mkIfaceName host)}"
    ]);
  };
}
