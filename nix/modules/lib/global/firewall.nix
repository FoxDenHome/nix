{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  util = foxDenLib.util;

  mkIfacePF = interfaces: lib.flatten (
    map (iface:
      map (pf: {
        target = {
          host = iface.host;
          interface = iface.name;
        };
        comment = if pf.comment == "" then "portforward-${iface.host}-${iface.name}" else pf.comment;
        inherit (pf) port protocol;
        inherit (iface) gateway;
      }) iface.firewall.portForwards)
    interfaces
  );
  mkPFRules = portForwards: map (fwd: {
    inherit (fwd) gateway protocol family comment;
    table = "nat";
    chain = "port-forward";
    action = "dnat";
    dstport = fwd.port;
    toAddresses = fwd.target;
  }) portForwards;
  mkIfaceRules = interfaces: lib.flatten (
    map (iface: let
      addresses = map util.removeIPCidr iface.addresses;
      snirouter = iface.snirouter;
      snirouterRules =
        if snirouter.enable then
          (if snirouter.httpPort > 0 then [{
            port = snirouter.httpPort;
            protocol = "tcp";
            comment = "auto-http-${iface.host}-${iface.name}";
          }] else []) ++
          (if snirouter.httpsPort > 0 then [{
            port = snirouter.httpsPort;
            protocol = "tcp";
            comment = "auto-https-${iface.host}-${iface.name}";
          }] else []) ++
          (if snirouter.quicPort > 0 then [{
            port = snirouter.quicPort;
            protocol = "udp";
            comment = "auto-quic-${iface.host}-${iface.name}";
          }] else [])
        else
          [];
      in lib.flatten (map (rule:
        (map (address: {
          table = "filter";
          chain = "forward";
          action = "accept";
          family = if util.isIPv6 address then "ipv6" else "ipv4";
          destination = address;
          dstport = rule.port or null;
          source = rule.source or null;
          protocol = rule.protocol or null;
          inherit (rule) comment;
          inherit (iface) gateway;
        }) addresses))
        (iface.firewall.ingressAcceptRules ++ iface.firewall.portForwards ++ snirouterRules))) interfaces);
in
{
  make = nixosConfigurations: let
    hostsBySystem = foxDenLib.global.config.get ["foxDen" "hosts" "hosts"] nixosConfigurations;
    gateways = foxDenLib.global.hosts.getGateways nixosConfigurations;

    resolveHostRef = rule: field: let
      ref = rule.${field};
      refType = builtins.typeOf ref;
      interface = hostsBySystem.${ref.system}.${ref.host}.interfaces.${ref.interface};
    in if refType == "string" || refType == "null"
      then
        [rule]
      else
        (lib.lists.filter (subRule: rule.family == null || subRule.family == rule.family)
          (map (address: rule // {
              ${field} = util.removeIPCidr address;
              family = if util.isIPv6 address then "ipv6" else "ipv4";
              inherit (interface) gateway;
            }) interface.addresses));

  in lib.attrsets.genAttrs gateways (gateway:
    map (lib.attrsets.filterAttrs (name: val: val != null && name != "gateway"))
      (lib.flatten (map (rule: let
        srcRules = resolveHostRef rule "source";
        dstRules = lib.flatten (map (srcRule: resolveHostRef srcRule "destination") srcRules);
        allRules = lib.flatten (map (dstRule: resolveHostRef dstRule "toAddresses") dstRules);
      in allRules) (nixpkgs.lib.lists.sortOn (rule: rule.priority)
        (lib.lists.filter (rule: rule.gateway == gateway) (foxDenLib.global.config.getList ["foxDen" "firewall" "rules"] nixosConfigurations)))))
  );

  nixosModule = { config, hostName, ... }: let
    hostRefType = with lib.types; submodule {
      options = {
        host = lib.mkOption {
          type = str;
        };
        interface = lib.mkOption {
          type = str;
          default = "default";
        };
        system = lib.mkOption {
          type = str;
          default = hostName;
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
        };
        chain = lib.mkOption {
          type = str;
        };
        action = lib.mkOption {
          type = enum [ "accept" "drop" "reject" "dnat" "masquerade" "jump" ];
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
          type = nullOr addrType;
          default = null;
        };
        toPorts = lib.mkOption {
          type = nullOr ints.u16;
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

    portForwardType = with lib.types; submodule {
      options = {
        family = lib.mkOption {
          type = enum [ "ipv4" ];
          default = "ipv4";
        };
        target = lib.mkOption {
          type = nullOr addrType;
          default = null;
        };
        gateway = lib.mkOption {
          type = str;
          default = config.foxDen.hosts.gateway;
        };
        port = lib.mkOption {
          type = ints.u16;
        };
        protocol = lib.mkOption {
          type = enum [ "tcp" "udp" ];
        };
        comment = lib.mkOption {
          type = str;
          default = "";
        };
      };
    };
  in {
    options.foxDen.firewall.rules = lib.mkOption {
      type = lib.types.listOf ruleType;
      default = [];
    };
    options.foxDen.firewall.portForwards = lib.mkOption {
      type = lib.types.listOf portForwardType;
      default = [];
    };

    config.foxDen.firewall.portForwards = mkIfacePF (foxDenLib.global.hosts.getInterfacesFromHosts config.foxDen.hosts.hosts);

    config.foxDen.firewall.rules = (mkPFRules config.foxDen.firewall.portForwards)
      ++ (mkIfaceRules (foxDenLib.global.hosts.getInterfacesFromHosts config.foxDen.hosts.hosts));
  };
}
