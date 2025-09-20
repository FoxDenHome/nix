{ nixpkgs, ... }:
let
  dns = import ./dns.nix { inherit nixpkgs; };
  globalConfig = import ./globalConfig.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;

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

  hostInfoType = with nixpkgs.lib.types; submodule {
    options = {
      serviceInterface = nixpkgs.lib.mkOption {
        type = str;
      };
      namespace = nixpkgs.lib.mkOption {
        type = str;
      };
      unit = nixpkgs.lib.mkOption {
        type = str;
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
        default = 2;
      };
      manageNetwork = nixpkgs.lib.mkOption {
        type = bool;
        default = true;
      };
    }
    (nixpkgs.lib.attrsets.listToAttrs (map (horizon: {
      name = horizon;
      value = nixpkgs.lib.mkOption {
        type = hostHorizonConfigType;
        default = {};
      };
    }) dns.allHorizons)));
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

  getAddresses = (config: host:
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

  mkRoutesGWSubnet = (ifcfg:
    (if (ifcfg.ipv4.address or "") != "" then [
      {
        Destination = "${ifcfg.ipv4.address}/32";
      }
    ] else []) ++ (if (ifcfg.ipv6.address or "") != "" then [
      {
        Destination = "${ifcfg.ipv6.address}/128";
      }
    ] else []));

  mkNetworkdAddresses = (addrs: 
    map (addr: "${addr.address}/${toString addr.prefixLength}")
    (nixpkgs.lib.lists.filter (addr: addr != "") addrs));
in
{
  hostType = hostType;
  hostHorizonConfigType = hostHorizonConfigType;
  hostDnsRecordType = hostDnsRecordType;

  # CFG.${name}.${host} = X -> [{${host} =  X, ...}, ...] -> [[X, ...], ...] -> [X, ...]
  allHosts = (nixosConfigurations:
              (nixpkgs.lib.flatten
                (map (nixpkgs.lib.attrsets.attrValues)
                  (nixpkgs.lib.attrsets.attrValues
                    (globalConfig.get ["foxDen" "hosts"] nixosConfigurations)))));

  mkOption = with nixpkgs.lib.types; (opts : nixpkgs.lib.mkOption (nixpkgs.lib.mergeAttrs {
    type = if opts.default == null then (nullOr hostType) else hostType;
  } opts));

  nixosModules.hosts = ({ config, pkgs, ... }:
  let
    hosts = nixpkgs.lib.attrsets.filterAttrs (name: host: host.manageNetwork) config.foxDen.hosts.hosts;
    ifcfg = config.foxDen.hosts.ifcfg;
    hostDriver = import (./hostDrivers + "/${config.foxDen.hosts.driver}.nix") { inherit ifcfg; inherit mkRoutesAK; inherit hosts; inherit nixpkgs; inherit pkgs; driverOpts = config.foxDen.hosts.driverOpts; };
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
          default = [ "8.8.8.8" ];
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
        type = (listOf routeType);
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

      info = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
        type = (attrsOf hostInfoType);
        default = {};
      };
    };

    config = {
      foxDen.hosts.info = (nixpkgs.lib.attrsets.mapAttrs
        (name: info: (nixpkgs.lib.mergeAttrs info {
          namespace = "/run/netns/host-${name}";
          unit = "netns-host-${name}.service";
        }))
        hostDriver.info);

      foxDen.hosts.ifcfg.network = nixpkgs.lib.mkDefault "40-${ifcfg.interface}";
      foxDen.hosts.routes = nixpkgs.lib.mkDefault (hostDriver.routes or (mkRoutesAK ifcfg "gateway"));
      foxDen.hosts.subnet = nixpkgs.lib.mkDefault (hostDriver.subnet or {
        ipv4 = ifcfg.ipv4.prefixLength;
        ipv6 = ifcfg.ipv6.prefixLength;
      });

      systemd = nixpkgs.lib.mkMerge [ hostDriver.config.systemd {
        network.networks."${foxDen.hosts.ifcfg.network}" = {
          name = ifcfg.interface;
          routes = mkRoutesAK ifcfg "gateway";
          address = mkNetworkdAddresses [ifcfg.ipv4 ifcfg.ipv6];
          dns = ifcfg.dns or [];

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = false;
          };
        };

        services = (nixpkgs.lib.attrsets.listToAttrs
          (map (name: let
            info = config.foxDen.hosts.info.${name};
            host = config.foxDen.hosts.hosts.${name};
            ipCmd = eSA "${pkgs.iproute2}/bin/ip";
            ipInNsCmd = "${ipCmd} netns exec ${eSA namespace} ${ipCmd}";
            namespace = "host-${name}";
          in
          {
            name = "netns-${namespace}";
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
                ++ (hostDriver.execStart { inherit host; inherit info; inherit ipCmd; inherit ipInNsCmd; })
                ++ [ "${ipCmd} link set ${eSA info.serviceInterface} netns ${eSA namespace}" ]
                ++ (map (addr:
                      "${ipInNsCmd} addr add ${eSA addr} dev ${eSA info.serviceInterface}")
                      (getAddresses config host))
                ++ [ "${ipInNsCmd} link set ${eSA info.serviceInterface} up" ]
                ++ (map (route:
                      "${ipInNsCmd} route add ${eSA route.Destination} dev ${eSA info.serviceInterface}" + (if route.Gateway != "" then " via ${eSA route.Gateway}" else ""))
                      config.foxDen.hosts.routes);
                ExecStop = [
                  "${ipCmd} netns del ${eSA namespace}"
                ] ++ (hostDriver.execStop { inherit host; inherit info; inherit ipCmd; inherit ipInNsCmd; });
              };
            };
          }) (nixpkgs.lib.attrsets.attrNames hosts)));
      }];
    };
  });
}
