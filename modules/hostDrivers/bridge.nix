{ nixpkgs, pkgs, driverOpts, ... } :
let
  util = import ../util.nix { };
  mkHostSuffix = host: util.mkHash8 host.name;
in
{
  configType = with nixpkgs.lib.types; submodule {
    options.bridge = nixpkgs.lib.mkOption {
      type = str;
      default = "br-default";
    };
  };

  netDevs = (hosts: {});

  networks = (hosts:
    nixpkgs.lib.attrsets.listToAttrs (
      nixpkgs.lib.lists.flatten
        (map (({ name, value }: let
          hostSuffix = mkHostSuffix value;
        in
        [
          {
            name = "60-host-${name}";
            value = {
              name = "veth-${hostSuffix}";
              bridge = [driverOpts.bridge];
              bridgeVLANs = [{
                PVID = value.vlan;
                EgressUntagged = value.vlan;
                VLAN = value.vlan;
              }];
            };
          }
        ])) (nixpkgs.lib.attrsets.attrsToList hosts))));

  execStart = (info: addrs: [
      "${pkgs.iproute2}/bin/ip link add '${info.hostInterface}' type veth peer name '${info.serviceInterface}'"
    ] ++ (map (addr:
      "${pkgs.iproute2}/bin/ip addr add '${addr}' '${info.serviceInterface}'"
    ) addrs) ++ [
      "${pkgs.iproute2}/bin/ip link set '${info.serviceInterface}' up"
    ]);

  infos = (hosts:
    nixpkgs.lib.attrsets.mapAttrs
      (name: value: let
        hostSuffix = mkHostSuffix value;
      in
      {
        hostInterface = "veth-${hostSuffix}";
        serviceInterface = "vpeer-${hostSuffix}";
      }) hosts);
}
