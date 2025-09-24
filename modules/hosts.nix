{ nixpkgs, ... }:
let
  util = import ./util.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;
  mkHostSuffix = host: util.mkHash8 host.name;

  ifcfgRouteType = with nixpkgs.lib.types; submodule {
    options = {
      Destination = nixpkgs.lib.mkOption {
        type = str;
      };
      Gateway = nixpkgs.lib.mkOption {
        type = str;
      };
    };
  };

  hostType = (nameDef: with nixpkgs.lib.types; submodule {
    options = {
      name = nixpkgs.lib.mkOption (if nameDef != null then {
        type = str;
        default = nameDef;
      } else {
        type = str;
      });
      dns = {
        name = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        zone = nixpkgs.lib.mkOption {
          type = str;
          default = "foxden.network";
        };
        ttl = nixpkgs.lib.mkOption {
          type = int;
          default = 3600;
        };
      };
      vlan = nixpkgs.lib.mkOption {
        type = int;
      };
      addresses = nixpkgs.lib.mkOption {
        type = listOf str;
      };
    };
  });

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

  mkHostInfo = (host: {
    namespace = "/run/netns/host-${host.name}";
    unit = "netns-host-${host.name}.service";
  });
in
{
  mkHostInfo = mkHostInfo;

  mkOption = with nixpkgs.lib.types; (inputs@{ nameDef, ... }: nixpkgs.lib.mkOption ({
    type = if (inputs.default or null) == null then (nullOr (hostType nameDef)) else (hostType nameDef);
    default = inputs.default or null;
  }));

  nixosModule = ({ config, pkgs, ... }:
  let
    hosts = config.foxDen.hosts.hosts;
    ifcfg = config.foxDen.hosts.ifcfg;

    hostDriver = import (./hostDrivers + "/${config.foxDen.hosts.driver}.nix")
      { inherit ifcfg hosts nixpkgs pkgs mkHostSuffix; driverOpts = config.foxDen.hosts.driverOpts; };

    netnsRoutes = (hostDriver.routes or ifcfg.routes) ++ config.foxDen.hosts.routes;
  in
  {
    options.foxDen.hosts = {
      hosts = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
        type = (listOf (hostType null));
        default = [];
      };

      ifcfg = with nixpkgs.lib.types; {
        dns = nixpkgs.lib.mkOption {
          type = listOf str;
        };
        addresses = nixpkgs.lib.mkOption {
          type = listOf str;
          default = [];
        };
        routes = nixpkgs.lib.mkOption {
          type = listOf ifcfgRouteType;
          default = [];
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

      foxDen.dns.records = nixpkgs.lib.flatten (map (host: let
        mkRecord = (addr: nixpkgs.lib.mkIf (host.dns.name != "") {
          zone = host.dns.zone;
          name = host.dns.name;
          type = if (util.isIPv6 addr) then "AAAA" else "A";
          ttl = host.dns.ttl;
          value = util.removeIpCidr addr;
          horizon = if (util.isPrivateIP addr) then "internal" else "external";
        });
      in
      (map mkRecord host.addresses)) hosts);

      systemd = nixpkgs.lib.mkMerge [
        hostDriver.config.systemd
        {
          # Configure host/primary network/bridge
          network.networks."${config.foxDen.hosts.ifcfg.network}" = {
            name = ifcfg.interface;
            routes = ifcfg.routes;
            address = ifcfg.addresses;
            dns = ifcfg.dns;

            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = false;
            };
          };

          # Configure each host's NetNS
          services = (nixpkgs.lib.attrsets.listToAttrs (map (host: let
            info = mkHostInfo host;
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
                      host.addresses)
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
          }) hosts));
        }
      ];
    };
  });
}
