{ nixpkgs, pkgs, driverOpts, ... } :
let
  util = import ../util.nix { };
  mkHostSuffix = host: util.mkHash8 host.name;
  eSA = nixpkgs.lib.strings.escapeShellArg;
in
{
  configType = with nixpkgs.lib.types; submodule {
    options.bridge = nixpkgs.lib.mkOption {
      type = str;
      default = "br-default";
    };
  };

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

  execStart = (info: [
    "-${pkgs.iproute2}/bin/ip link del ${eSA info.hostInterface}"
    "${pkgs.iproute2}/bin/ip link add ${eSA info.hostInterface} type veth peer name ${eSA info.serviceInterface}"
  ]);

  execStop = (info: [
    "${pkgs.iproute2}/bin/ip link del ${eSA info.hostInterface}"
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
