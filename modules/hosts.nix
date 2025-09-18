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
      }) dns.allHorizons))
    );
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
    hostDriver = import (./hostDrivers + "/${config.foxDen.hostDriver}.nix") { inherit nixpkgs; };
    managedHostsList = nixpkgs.lib.lists.filter (host: host.manageNetwork) (nixpkgs.lib.attrsets.attrValues config.foxDen.hosts);
  in
  {
    options.foxDen.hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = (attrsOf (nullOr hostType));
      default = [];
    };

    options.foxDen.hostDriver = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = enum [ "bridge" "sriov" ];
      default = "bridge";
    };
    options.foxDen.hostDriverOpts = nixpkgs.lib.mkOption {
      type = hostDriver.configType;
      default = {};
    };

    config.systemd.network.netdevs = hostDriver.netDevs config.foxDen.hostDriverOpts managedHostsList;
    config.systemd.network.networks = hostDriver.networks config.foxDen.hostDriverOpts managedHostsList;
    config.networking.useNetworkd = true;
  });
}
