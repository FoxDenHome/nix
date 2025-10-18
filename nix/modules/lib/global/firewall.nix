{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  util = foxDenLib.util;

  mkRules = interfaces: lib.flatten (
    map (iface: let
      rules = let
        addresses = map util.removeIPCidr iface.addresses;
        snirouter = iface.snirouter;
        snirouterRules =
          if snirouter.enable then
            (if snirouter.httpPort > 0 then [{
              port = snirouter.httpPort;
              protocol = "tcp";
              source = null;
            }] else []) ++
            (if snirouter.httpsPort > 0 then [{
              port = snirouter.httpsPort;
              protocol = "tcp";
              source = null;
            }] else []) ++
            (if snirouter.quicPort > 0 then [{
              port = snirouter.quicPort;
              protocol = "udp";
              source = null;
            }] else [])
          else
            [];
        in
          lib.flatten (map (rule:
            (map (address: {
              family = if util.isIPv6 address then "ipv6" else "ipv4";
              destination = address;
              dstport = rule.port;
              inherit (rule) source protocol;
              inherit (iface) gateway;
            }) addresses))
            (iface.firewall.openPorts ++ snirouterRules));
      comment = if iface.name == "default" then "web-${iface.host}" else "web-${iface.host}-${iface.name}";
    in map (rule: rule // { inherit comment; }) rules) interfaces);
in
{
  make = nixosConfigurations: let
    hosts = foxDenLib.global.config.getAttrSet ["foxDen" "hosts" "hosts"] nixosConfigurations;
    gateways = foxDenLib.global.hosts.getGateways nixosConfigurations;

    resolveRuleRef = rule: field: let
      ref = rule.${field};
      refType = builtins.typeOf ref;
      interface = hosts.${ref.host}.interfaces.${ref.interface};
    in if refType == "string" || refType == "null"
      then
        [rule]
      else
        (lib.lists.filter (subRule: rule.family == null || subRule.family == rule.family)
          (map (address: rule // {
              ${field} = address;
              family = if util.isIPv6 address then "ipv6" else "ipv4";
              inherit (interface) gateway;
            }) interface.addresses));

  in lib.attrsets.genAttrs gateways (gateway:
    map (lib.attrsets.filterAttrs (name: val: val != null && name != "gateway"))
      (lib.flatten (map (rule: let
        srcRules = resolveRuleRef rule "source";
        allRules = lib.flatten (map (srcRule: resolveRuleRef srcRule "destination") srcRules);
      in allRules) (nixpkgs.lib.lists.sortOn (rule: rule.priority)
        (lib.lists.filter (rule: rule.gateway == gateway) (foxDenLib.global.config.getList ["foxDen" "firewall" "rules"] nixosConfigurations)))))
  );

  nixosModule = { config, ... }: let
    hostRefType = with lib.types; submodule {
      options = {
        host = lib.mkOption {
          type = str;
        };
        interface = lib.mkOption {
          type = str;
          default = "default";
        };
      };
    };

    addrType = lib.types.either hostRefType lib.types.str;

    ruleType = with lib.types; submodule {
      options = {
        family = lib.mkOption {
          type = nullOr (enum [ "ipv4" "ipv6" ]);
          default = null;
        };
        table = lib.mkOption {
          type = enum [ "filter" "nat" "mangle" "raw" ];
          default = "filter";
        };
        chain = lib.mkOption {
          type = str;
          default = "forward";
        };
        action = lib.mkOption {
          type = enum [ "accept" "drop" "reject" "dnat" "masquerade" "jump" ];
          default = "accept";
        };
        srcport = lib.mkOption {
          type = nullOr ints.u16;
          default = null;
        };
        dstport = lib.mkOption {
          type = nullOr ints.u16;
          default = null;
        };
        protocol = lib.mkOption {
          type = nullOr (enum [ "tcp" "udp" ]);
          default = null;
        };
        source = lib.mkOption {
          type = nullOr addrType;
          default = null;
        };
        destination = lib.mkOption {
          type = nullOr addrType;
          default = null;
        };
        gateway = lib.mkOption {
          type = str;
          default = config.foxDen.hosts.gateway;
        };
        jumpTarget = lib.mkOption {
          type = str;
          default = "";
        };
        toAddresses = lib.mkOption {
          type = nullOr str;
          default = null;
        };
        toPorts = lib.mkOption {
          type = nullOr str;
          default = null;
        };
        comment = lib.mkOption {
          type = str;
          default = "";
        };
        priority = lib.mkOption {
          type = int;
          default = 0;
        };
        rejectWith = lib.mkOption {
          type = nullOr str;
          default = null;
        };
      };
    };
  in {
    options.foxDen.firewall.rules = lib.mkOption {
      type = lib.types.listOf ruleType;
      default = [];
    };

    config.foxDen.firewall.rules = mkRules (foxDenLib.global.hosts.getInterfacesFromHosts config.foxDen.hosts.hosts);
  };
}
