{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  globalConfig = foxDenLib.global.config;

  getInterfaces = nixosConfigurations: let
    hosts = globalConfig.getAttrSet ["foxDen" "hosts" "hosts"] nixosConfigurations;
  in
    lib.flatten (map (host: lib.attrsets.attrValues host.interfaces) (lib.attrsets.attrValues hosts));
in
{
  inherit getInterfaces;
  getGateways = nixosConfigurations: lib.lists.unique (map (iface: iface.gateway) (getInterfaces nixosConfigurations));
}
