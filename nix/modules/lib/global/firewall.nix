{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  util = foxDenLib.util;

  mkForGateway = gateway: interfaces: let
    mkRules = iface: let
      addresses = map util.removeIPCidr iface.addresses;
      snirouter = iface.snirouter;
      snirouterRules =
        if snirouter.enable then
          (if snirouter.httpPort > 0 then [{
            port = snirouter.httpPort;
            protocol = "tcp";
            internalOnly = false;
          }] else []) ++
          (if snirouter.httpsPort > 0 then [{
            port = snirouter.httpsPort;
            protocol = "tcp";
            internalOnly = false;
          }] else []) ++
          (if snirouter.quicPort > 0 then [{
            port = snirouter.quicPort;
            protocol = "udp";
            internalOnly = false;
          }] else [])
        else
          [];
      in
        lib.flatten (map (rule:
          (map (address: {
            inherit (rule) port protocol internalOnly;
            inherit address;
            family = if util.isIPv6 address then "ipv6" else "ipv4";
          }) addresses))
          (iface.firewall.openPorts ++ snirouterRules));
  in
    lib.flatten (
      map (iface: let
        rules = mkRules iface;
        targetName = if iface.name == "default" then iface.host else "${iface.host}-${iface.name}";
      in map (rule: rule // { inherit targetName; }) rules) interfaces);
in
{
  make = nixosConfigurations: let
    interfaces = foxDenLib.global.hosts.getInterfaces nixosConfigurations;
    gateways = foxDenLib.global.hosts.getGateways nixosConfigurations;
  in lib.attrsets.genAttrs gateways (gateway:
    mkForGateway gateway interfaces
  );
}
