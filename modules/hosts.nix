{ nixpkgs, ... }:
let
  util = import ./util.nix { inherit nixpkgs; };
  dns = import ./dns.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkHostSuffix = host: util.mkHash8 host.name;

  ifcfgAddressType = with nixpkgs.lib.types; submodule {
    options = {
      address = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      gateway = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      prefixLength = nixpkgs.lib.mkOption {
        type = int;
        default = null;
      };
    };
  };

  hostDnsRecordType = with nixpkgs.lib.types; submodule {
    options = {
      type = nixpkgs.lib.mkOption {
        type = str;
        default = "A";
      };
      value = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      ttl = nixpkgs.lib.mkOption {
        type = int;
        default = dns.defaultTtl;
      };
    };
  };

  hostHorizonConfigType = with nixpkgs.lib.types; submodule {
    options = {
      ipTtl = nixpkgs.lib.mkOption {
        type = int;
        default = dns.defaultTtl;
      };
      ipv4 = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      ipv6 = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      records = nixpkgs.lib.mkOption {
        type = listOf hostDnsRecordType;
        default = [];
      };
    };
  };

  hostType = with nixpkgs.lib.types; submodule {
    options = (nixpkgs.lib.mergeAttrs
    {
      name = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
      root = nixpkgs.lib.mkOption {
        type = str;
        default = "foxden.network";
      };
      vlan = nixpkgs.lib.mkOption {
        type = int;
      };
      manageNetwork = nixpkgs.lib.mkOption {
        type = bool;
        default = true;
      };
    }
    (nixpkgs.lib.attrsets.genAttrs dns.allHorizons (horizon: nixpkgs.lib.mkOption {
      type = hostHorizonConfigType;
      default = {};
    })));
  };

  routeType = with nixpkgs.lib.types; submodule {
    options = {
      Destination = nixpkgs.lib.mkOption {
        type = str;
        default = "default";
      };
      Gateway = nixpkgs.lib.mkOption {
        type = str;
        default = "";
      };
    };
  };

  mkIpCmdAddresses = (config: host:
    (map (addr: 
      "${addr}/${toString config.foxDen.hosts.subnet.ipv4}")
      (nixpkgs.lib.lists.filter (val: val != "") [
        host.internal.ipv4
        host.external.ipv4
      ])
    ) ++ (map (addr:
      "${addr}/${toString config.foxDen.hosts.subnet.ipv6}")
      (nixpkgs.lib.lists.filter (val: val != "") [
        host.internal.ipv6
        host.external.ipv6
      ])
    ));

  mkRoutesAK = (ifcfg: addrKey: let
    addr.ipv4 = ifcfg.ipv4.${addrKey} or "";
    addr.ipv6 = ifcfg.ipv6.${addrKey} or "";
  in
    (if (addr.ipv4 or "") != "" then [
      {
        Destination = "0.0.0.0/0";
        Gateway = addr.ipv4;
      }
    ] else []) ++ (if (addr.ipv6 or "") != "" then [
      {
        Destination = "::/0";
        Gateway = addr.ipv6;
      }
    ] else []));

  mkNetworkAddresses = (addrs:
    map (addr: "${addr.address}/${toString addr.prefixLength}")
    (nixpkgs.lib.lists.filter (addr: addr != "") addrs));

  mkHostInfo = (name: {
    namespace = "/run/netns/host-${name}";
    unit = "netns-host-${name}.service";
  });
in
{
  hostType = hostType;
  hostHorizonConfigType = hostHorizonConfigType;
  hostDnsRecordType = hostDnsRecordType;

  mkHostInfo = mkHostInfo;
  mkHostConfig = (config: name: config.foxDen.hosts.hosts.${name});

  mkOption = with nixpkgs.lib.types; (opts: nixpkgs.lib.mkOption (nixpkgs.lib.mergeAttrs {
    type = if opts.default == null then (nullOr hostType) else hostType;
  } opts));

  nixosModule = ({ config, pkgs, ... }:
  let
    hosts = nixpkgs.lib.attrsets.filterAttrs (name: host: host.manageNetwork) config.foxDen.hosts.hosts;
    ifcfg = config.foxDen.hosts.ifcfg;
    hostDriver = import (./hostDrivers + "/${config.foxDen.hosts.driver}.nix") { inherit ifcfg hosts nixpkgs pkgs mkRoutesAK mkHostSuffix; driverOpts = config.foxDen.hosts.driverOpts; };
    netnsRoutes = (hostDriver.routes or (mkRoutesAK ifcfg "gateway")) ++ config.foxDen.hosts.routes;
  in
  {
    options.foxDen.hosts = {
      hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
        type = (attrsOf hostType);
        default = {};
      };

      subnet = {
        ipv4 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = int;
          default = 24;
        };
        ipv6 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = int;
          default = 64;
        };
      };

      ifcfg = with nixpkgs.lib.types; {
        dns = nixpkgs.lib.mkOption {
          type = listOf str;
        };
        ipv4 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = nullOr ifcfgAddressType;
          default = null;
        };
        ipv6 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = nullOr ifcfgAddressType;
          default = null;
        };
        interface = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = str;
        };
        network = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
          type = str;
        };
      };

      routes = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
        type = listOf routeType;
        default = [];
      };

      driver = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
        type = enum [ "bridge" "routed" ];
        default = "bridge";
      };

      driverOpts = nixpkgs.lib.mkOption {
        type = hostDriver.configType;
        default = {};
      };
    };

    config = {
      foxDen.hosts.ifcfg.network = nixpkgs.lib.mkDefault "40-${ifcfg.interface}";
      foxDen.hosts.subnet = nixpkgs.lib.mkDefault (hostDriver.subnet or {
        ipv4 = ifcfg.ipv4.prefixLength;
        ipv6 = ifcfg.ipv6.prefixLength;
      });

      systemd = nixpkgs.lib.mkMerge [ hostDriver.config.systemd {
        # Configure host/primary network/bridge
        network.networks."${config.foxDen.hosts.ifcfg.network}" = {
          name = ifcfg.interface;
          routes = mkRoutesAK ifcfg "gateway";
          address = mkNetworkAddresses [ifcfg.ipv4 ifcfg.ipv6];
          dns = ifcfg.dns or [];

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = false;
          };
        };

        # Configure each host's NetNS
        services = (nixpkgs.lib.attrsets.listToAttrs
          (map (name: let
            host = config.foxDen.hosts.hosts.${name};
            info = mkHostInfo name;
            namespace = (nixpkgs.lib.strings.removePrefix "/run/netns/" info.namespace);

            ipCmd = eSA "${pkgs.iproute2}/bin/ip";
            ipInNsCmd = "${ipCmd} netns exec ${eSA namespace} ${ipCmd}";

            mkServiceInterface = hostDriver.serviceInterface or (host: "host-${mkHostSuffix host}");
            serviceInterface = mkServiceInterface host;
            driverRunParams = { inherit host ipCmd ipInNsCmd serviceInterface; };
          in
          {
            name = (nixpkgs.lib.strings.removeSuffix ".service" info.unit);
            value = {
              description = "NetNS ${namespace}";
              unitConfig = {
                StopWhenUnneeded = true;
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;

                ExecStart = [
                  "-${ipCmd} netns del ${eSA namespace}"
                  "${ipCmd} netns add ${eSA namespace}"
                  "${ipInNsCmd} addr add 127.0.0.1/8 dev lo"
                  "${ipInNsCmd} addr add ::1/128 dev lo noprefixroute"
                  "${ipInNsCmd} link set lo up"
                ]
                ++ (hostDriver.execStart driverRunParams)
                ++ [ "${ipCmd} link set ${eSA serviceInterface} netns ${eSA namespace}" ]
                ++ (map (addr:
                      "${ipInNsCmd} addr add ${eSA addr} dev ${eSA serviceInterface}")
                      (mkIpCmdAddresses config host))
                ++ [ "${ipInNsCmd} link set ${eSA serviceInterface} up" ]
                ++ (map (route:
                      "${ipInNsCmd} route add ${eSA route.Destination} dev ${eSA serviceInterface}" + (if (route.Gateway or "") != "" then " via ${eSA route.Gateway}" else ""))
                      netnsRoutes);

                ExecStop =
                  (hostDriver.execStop driverRunParams)
                  ++ [
                    "${ipCmd} netns del ${eSA namespace}"
                  ];
              };
            };
          }) (nixpkgs.lib.attrsets.attrNames hosts)));
      }];
    };
  });
}
