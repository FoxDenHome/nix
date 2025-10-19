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
    inherit (fwd) gateway protocol comment;
    table = "nat";
    chain = "port-forward";
    action = "dnat";
    dstport = fwd.port;
    toAddresses = if builtins.typeOf fwd.target == "set" then fwd.target // { family = "ipv4"; } else fwd.target;
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

      filteredAddresses = if ref.family == null then interface.addresses
        else lib.filter (addr: if ref.family == "ipv4" then !util.isIPv6 addr else util.isIPv6 addr) interface.addresses;
    in if refType == "set"
      then
        (map (address: rule // {
            ${field} = util.removeIPCidr address;
            inherit (interface) gateway;
          }) filteredAddresses)
      else
        [rule];

    nullOrSameFamily = field1: field2: rule: let
      val1 = rule.${field1};
      val2 = rule.${field2};
    in if val1 != null && val2 != null then (util.isIPv6 val1) == (util.isIPv6 val2) else true;

  in lib.attrsets.genAttrs gateways (gateway:
    map (lib.attrsets.filterAttrs (name: val: val != null && name != "gateway"))
      (lib.flatten (map (rule: let
        srcRules = resolveHostRef rule "source";
        dstRules = lib.flatten (map (srcRule: resolveHostRef srcRule "destination") srcRules);
        allRules = lib.flatten (map (dstRule: resolveHostRef dstRule "toAddresses") dstRules);
        allSameFamilyFilter = rule: (nullOrSameFamily "source" "destination" rule) && (nullOrSameFamily "source" "toAddresses" rule);
      in lib.lists.filter allSameFamilyFilter allRules) (nixpkgs.lib.lists.sortOn (rule: rule.priority)
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
        family = lib.mkOption {
          type = nullOr (enum [ "ipv4" "ipv6" ]);
          default = null;
        };
      };
    };

    addrType = lib.types.either hostRefType lib.types.str;

    ruleType = with lib.types; submodule {
      options = {
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
