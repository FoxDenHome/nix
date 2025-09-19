{ nixpkgs, ... }:
let
  dns = import ./dns.nix { inherit nixpkgs; };
  globalConfig = import ./globalConfig.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;

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
      hostInterface = nixpkgs.lib.mkOption {
        type = (nullOr str);
      };
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
      target = nixpkgs.lib.mkOption {
        type = str;
        default = "default";
      };
      gateway = nixpkgs.lib.mkOption {
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
    )
  );
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
    hostDriver = import (./hostDrivers + "/${config.foxDen.hosts.driver}.nix") { inherit nixpkgs; inherit pkgs; driverOpts = config.foxDen.hosts.driverOpts; };
    managedHosts = nixpkgs.lib.attrsets.filterAttrs (name: host: host.manageNetwork) config.foxDen.hosts.hosts;
  in
  {
    options.foxDen.hosts.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf hostType);
      default = {};
    };

    options.foxDen.hosts.subnet.ipv4 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = int;
      default = 24;
    };
    options.foxDen.hosts.subnet.ipv6 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = int;
      default = 64;
    };

    options.foxDen.hosts.routes = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (listOf routeType);
      default = [];
    };

    options.foxDen.hosts.driver = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = enum [ "bridge" "sriov" ];
      default = "bridge";
    };

    options.foxDen.hosts.driverOpts = nixpkgs.lib.mkOption {
      type = hostDriver.configType;
      default = {};
    };

    options.foxDen.hosts.info = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf hostInfoType);
      default = {};
    };

    config.foxDen.hosts.info = (nixpkgs.lib.attrsets.mapAttrs
      (name: info: (nixpkgs.lib.mergeAttrs info {
        namespace = "/run/netns/host-${name}";
        unit = "netns-host-${name}.service";
      }))
      (hostDriver.infos managedHosts));

    config.systemd.services = (nixpkgs.lib.attrsets.listToAttrs
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
              "${ipInNsCmd} addr add ::1/128 dev lo"
              "${ipInNsCmd} link set lo up"
            ]
            ++ (hostDriver.execStart info)
            ++ [ "${ipCmd} link set ${eSA info.serviceInterface} netns ${eSA namespace}" ]
            ++ (map (addr:
                  "${ipInNsCmd} addr add ${eSA addr} dev ${eSA info.serviceInterface}")
                  (getAddresses config host))
            ++ [ "${ipInNsCmd} link set ${eSA info.serviceInterface} up" ]
            ++ (map (route:
                "-${ipInNsCmd} route add ${eSA route.target}" + (if route.gateway != "" then " via ${eSA route.gateway}" else "dev ${eSA info.serviceInterface}"))
                  config.foxDen.hosts.routes);
            ExecStop = [
              "${ipCmd} netns del ${eSA namespace}"
            ] ++ (hostDriver.execStop info);
          };
        };
      }) (nixpkgs.lib.attrsets.attrNames managedHosts)));

    config.systemd.network.networks = hostDriver.networks managedHosts;
    config.networking.useNetworkd = true;
  });
}
