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
        type = str;
      };
      serviceInterface = nixpkgs.lib.mkOption {
        type = str;
      };
      slice = nixpkgs.lib.mkOption {
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

  nixosModules.hosts = ({ config, ... }:
  let
    hostDriver = import (./hostDrivers + "/${config.foxDen.hostDriver}.nix") { inherit nixpkgs; driverOpts = config.foxDen.hostDriverOpts; };
    managedHosts = nixpkgs.lib.attrsets.filterAttrs (name: host: host.manageNetwork) config.foxDen.hosts;
  in
  {
    options.foxDen.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf hostType);
      default = {};
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
        slice = "host-${name}";
      }))
      (hostDriver.infos managedHosts));

    config.systemd.slices = (nixpkgs.lib.attrsets.listToAttrs
      (map (name: {
        name = config.foxDen.hostInfo.${name}.slice;
        value = {
          description = "Slice for ${name}";
          sliceConfig = {
            RestrictNetworkInterfaces = config.foxDen.hostInfo.${name}.serviceInterface;
            PrivateNetwork = true;
          };
          serviceConfig = {
            PrivateNetwork = true;
          };
        };
      }) (nixpkgs.lib.attrsets.attrNames managedHosts)));

    config.systemd.network.netdevs = hostDriver.netDevs managedHosts;
    config.systemd.network.networks = hostDriver.networks managedHosts;
    config.networking.useNetworkd = true;
  });
}
