{ nixpkgs, ... }:
let
  dns = import ./dns.nix { inherit nixpkgs; };
  globalConfig = import ./globalConfig.nix { inherit nixpkgs; };

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
        type = (oneOf str);
      };
      serviceInterface = nixpkgs.lib.mkOption {
        type = str;
      };
      namespace = nixpkgs.lib.mkOption {
        type = str;
      };
      requires = nixpkgs.lib.mkOption {
        type = listOf str;
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

  mkBaseNetwork = (config: (name: host: {
    addresses = (map (addr: {
      Address = "${addr}/${toString config.foxDen.subnet.ipv4}";
    }) (nixpkgs.lib.lists.filter (val : val != null && val != "") [
      host.internal.ipv4
      host.external.ipv4
    ])) ++ (map (addr: {
      Address = "${addr}/${toString config.foxDen.subnet.ipv6}";
    }) (nixpkgs.lib.lists.filter (val : val != null && val != "") [
      host.internal.ipv6
      host.external.ipv6
    ]));
  }));
in
{
  hostType = hostType;
  hostHorizonConfigType = hostHorizonConfigType;
  hostDnsRecordType = hostDnsRecordType;

  # CFG.${name}.${host} = X -> [{${host} =  X, ...}, ...] -> [[X, ...], ...] -> [X, ...]
  allHosts = (nixpkgs.lib.flatten
              (map (nixpkgs.lib.attrsets.attrValues)
                (nixpkgs.lib.attrsets.attrValues
                  (globalConfig.get ["foxDen" "hosts"]))));

  mkOption = with nixpkgs.lib.types; (opts : nixpkgs.lib.mkOption (nixpkgs.lib.mergeAttrs {
    type = if opts.default == null then (nullOr hostType) else hostType;
  } opts));

  nixosModules.hosts = ({ config, pkgs, ... }:
  let
    hostDriver = import (./hostDrivers + "/${config.foxDen.hostDriver}.nix") { inherit nixpkgs; driverOpts = config.foxDen.hostDriverOpts; };
    managedHosts = nixpkgs.lib.attrsets.filterAttrs (name: host: host.manageNetwork) config.foxDen.hosts;
  in
  {
    options.foxDen.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf hostType);
      default = {};
    };

    options.foxDen.subnet.ipv4 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = int;
      default = 24;
    };

    options.foxDen.subnet.ipv6 = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = int;
      default = 64;
    };

    options.foxDen.hostDriver = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = enum [ "bridge" "sriov" ];
      default = "bridge";
    };

    options.foxDen.hostDriverOpts = nixpkgs.lib.mkOption {
      type = hostDriver.configType;
      default = {};
    };

    options.foxDen.hostInfo = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf hostInfoType);
      default = {};
    };

    config.foxDen.hostInfo = (nixpkgs.lib.attrsets.mapAttrs
      (name: info: (nixpkgs.lib.mergeAttrs info {
        namespace = "/run/netns/host-${name}";
        requires = ["netns-host-${name}.service"];
      }))
      (hostDriver.infos managedHosts));

    config.systemd.services = (nixpkgs.lib.attrsets.listToAttrs
      (map (name: let
         info = config.foxDen.hostInfo.${name};
       in
       {
        name = "netns-host-${name}";
        value = {
          description = "NetNS host service for ${name}";
          unitConfig = {
            StopWhenUnneeded = true;
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = [
              "${pkgs.iproute2}/bin/ip netns add 'host-${name}'"
              "${pkgs.iproute2}/bin/ip link set '${info.serviceInterface}' netns 'host-${name}'"
            ];
            ExecStop = [
              "${pkgs.iproute2}/bin/ip netns del 'host-${name}'"
            ];
          };
        };
      }) (nixpkgs.lib.attrsets.attrNames managedHosts)));

    config.systemd.network.netdevs = hostDriver.netDevs managedHosts;
    config.systemd.network.networks = hostDriver.networks (mkBaseNetwork config) managedHosts;
    config.networking.useNetworkd = true;
  });
}
