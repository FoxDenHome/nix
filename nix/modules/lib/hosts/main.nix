{ nixpkgs, foxDenLib, ... }:
let
  util = foxDenLib.util;
  eSA = nixpkgs.lib.strings.escapeShellArg;

  cnameType = with nixpkgs.lib.types; submodule {
    options = {
      name = nixpkgs.lib.mkOption {
        type = str;
      };
      zone = nixpkgs.lib.mkOption {
        type = str;
      };
      type = nixpkgs.lib.mkOption {
        type = enum [ "CNAME" "ALIAS" ];
        default = "CNAME";
      };
    };
  };

  interfaceType = with nixpkgs.lib.types; submodule {
    options = {
      driver = nixpkgs.lib.mkOption {
        type = enum (nixpkgs.lib.attrsets.attrNames foxDenLib.hosts.drivers);
      };
      driverOpts = nixpkgs.lib.mkOption {
        type = attrsOf anything; # TODO: Host driver schema
        default = {};
      };
      mac = nixpkgs.lib.mkOption {
        type = nullOr str;
        default = null;
      };
      snirouter = {
        enable = nixpkgs.lib.mkOption {
          type = bool;
          default = false;
        };
        proxyProtocol = nixpkgs.lib.mkOption {
          type = bool;
          default = true;
        };
        httpPort = nixpkgs.lib.mkOption {
          type = ints.u16;
          default = 80;
        };
        httpsPort = nixpkgs.lib.mkOption {
          type = ints.u16;
          default = 443;
        };
        quicPort = nixpkgs.lib.mkOption {
          type = ints.u16;
          default = 443;
        };
      };
      dns = {
        name = nixpkgs.lib.mkOption {
          type = str;
          default = "";
        };
        auxAddresses = nixpkgs.lib.mkOption {
          type = uniq (listOf foxDenLib.types.ip);
          default = [];
        };
        zone = nixpkgs.lib.mkOption {
          type = str;
          default = "foxden.network";
        };
        ttl = nixpkgs.lib.mkOption {
          type = ints.positive;
          default = 3600;
        };
        dynDns = nixpkgs.lib.mkOption {
          type = bool;
          default = false;
        };
        dynDnsTtl = nixpkgs.lib.mkOption {
          type = nullOr ints.positive;
          default = 300;
        };
      };
      cnames = nixpkgs.lib.mkOption {
        type = listOf cnameType;
        default = [];
      };
      addresses = nixpkgs.lib.mkOption {
        type = uniq (listOf foxDenLib.types.ip);
      };
      routes = nixpkgs.lib.mkOption {
        type = nullOr (listOf routeType);
        default = [];
      };
      sysctls = nixpkgs.lib.mkOption {
        type = attrsOf str;
        default = {};
      };
    };
  };

  routeType = with nixpkgs.lib.types; submodule {
    options = {
      Destination = nixpkgs.lib.mkOption {
        type = nullOr foxDenLib.types.ip;
        default = null;
      };
      Gateway = nixpkgs.lib.mkOption {
        type = nullOr foxDenLib.types.ipWithoutCidr;
        default = null;
      };
    };
  };

  hostType = with nixpkgs.lib.types; submodule {
    options = {
      interfaces = nixpkgs.lib.mkOption {
        type = attrsOf interfaceType;
      };
      nameservers = nixpkgs.lib.mkOption {
        type = listOf str;
        default = [];
      };
    };
  };

  getByName = (config: name: let
    namespace = "host-${name}";
  in {
    inherit name;
    namespace = namespace;
    namespacePath = "/run/netns/${namespace}";
    unit = "netns-host-${name}.service";
    resolvConf = "/etc/foxden/hosts/${name}/resolv.conf";
  } // config.foxDen.hosts.hosts.${name});
in
{
  getByName = getByName;

  nixosModule = ({ config, pkgs, foxDenLib, ... }:
  let
    hostIndexHex1 = nixpkgs.lib.toHexString (config.foxDen.hosts.index or 0);
    hostIndexHex = if (nixpkgs.lib.stringLength hostIndexHex1 == 1) then "0${hostIndexHex1}" else hostIndexHex1;

    mkHashMac = (hash: "e6:21:${hostIndexHex}:${builtins.substring 0 2 hash}:${builtins.substring 2 2 hash}:${builtins.substring 4 2 hash}");

    hosts = map (getByName config) (nixpkgs.lib.attrsets.attrNames config.foxDen.hosts.hosts);
    mapIfaces = (host: map ({ name, value }:  value // rec {
      inherit host name;
      suffix = util.mkShortHash 6 (host.name + "|" + name);
      mac = if value.mac != null then value.mac else (mkHashMac suffix);
    }) (nixpkgs.lib.attrsets.attrsToList host.interfaces));
    interfaces = nixpkgs.lib.flatten (map mapIfaces hosts);

    ifaceHasV4 = (iface: nixpkgs.lib.any util.isIPv4 iface.addresses);
    ifaceHasV6 = (iface: nixpkgs.lib.any util.isIPv6 iface.addresses);

    ifaceFirstV4 = (iface: nixpkgs.lib.findFirst util.isIPv4 "127.0.0.1" iface.addresses);
    ifaceFirstV6 = (iface: nixpkgs.lib.findFirst util.isIPv6 "::1" iface.addresses);

    mkIfaceDynDnsOne = (iface: check: type: value: if (check iface) then [
      {
        zone = iface.dns.zone;
        name = iface.dns.name;
        type = type;
        ttl = iface.dns.dynDnsTtl;
        value = util.removeIPCidr (value iface);
        dynDns = true;
        horizon = "external";
      }
    ] else []);

    mkIfaceDynDns = (iface: if iface.dns.dynDns then
      (mkIfaceDynDnsOne iface ifaceHasV4 "A" ifaceFirstV4) ++
      (mkIfaceDynDnsOne iface ifaceHasV6 "AAAA" ifaceFirstV6)
    else []);
  in
  {
    options.foxDen.hosts = with nixpkgs.lib.types; {
      hosts = nixpkgs.lib.mkOption {
        type = attrsOf hostType;
        default = {};
      };
      gateway = nixpkgs.lib.mkOption {
        type = str;
        default = "default";
      };
      usedMacAddresses = nixpkgs.lib.mkOption {
        type = addCheck (listOf str) (macs: let
          uniqueMacs = nixpkgs.lib.lists.uniqueString macs;
        in (nixpkgs.lib.lists.length macs) == (nixpkgs.lib.lists.length uniqueMacs));
        description = ''
          List of MAC addresses that are already in use on your network.
          This is used to avoid generating colliding MAC addresses for interfaces.
        '';
      };
      ptrZones = nixpkgs.lib.mkOption {
        type = listOf str;
        default = [
          "c.1.2.2.0.f.8.e.0.a.2.ip6.arpa"
          "0.f.4.4.d.7.e.0.a.2.ip6.arpa"
          "e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa"
          "10.in-addr.arpa"
          "41.96.100.in-addr.arpa"
        ];
      };
      index = nixpkgs.lib.mkOption {
        type = ints.u8;
        default = 0;
      };
    };

    config = {
      foxDen.hosts.usedMacAddresses = map (iface: iface.mac) interfaces;

      foxDen.dns.records = (nixpkgs.lib.flatten (map
          (iface: let
            mkRecord = (addr: nixpkgs.lib.mkIf (iface.dns.name != "") {
              inherit (iface.dns) zone name ttl;
              type = if (util.isIPv6 addr) then "AAAA" else "A";
              value = util.removeIPCidr addr;
              horizon = if (util.isPrivateIP addr) then "internal" else "external";
            });
            mkPtr = (addr: let
              revName = util.mkPtr addr;
              zone = nixpkgs.lib.findFirst (zone: nixpkgs.lib.strings.hasSuffix zone ".${revName}") "" config.foxDen.hosts.ptrZones;
            in nixpkgs.lib.mkIf (iface.dns.name != "" && zone != "") {
              inherit (iface.dns) ttl;
              inherit zone;
              name = nixpkgs.lib.strings.removeSuffix ".${zone}" revName;
              type = "PTR";
              value = "${foxDenLib.global.dns.mkHost iface.dns}.";
              horizon = if (util.isPrivateIP addr) then "internal" else "external";
            });
            ifaceCnames = map (cname: {
              inherit (iface.dns) ttl;
              inherit (cname) name zone type;
              value = "${foxDenLib.global.dns.mkHost iface.dns}.";
              horizon = "*"; # TODO: This might need to be conditional if there is v4/v6 only hosts with CNAMEs
            }) iface.cnames;
          in
          (
            (map mkRecord (iface.addresses ++ iface.dns.auxAddresses))
            ++ (map mkPtr iface.addresses)
            ++ (mkIfaceDynDns iface)
            ++ ifaceCnames
          ))
        interfaces));

      environment.etc = nixpkgs.lib.listToAttrs (map (host: {
        name = nixpkgs.lib.strings.removePrefix "/etc/" host.resolvConf;
        value.text = ''
          # Generated by foxDen
          ${nixpkgs.lib.concatMapStrings (ns: "nameserver ${ns}\n") host.nameservers}
        '';
      }) hosts);

      systemd = nixpkgs.lib.mkMerge (
        (map ({ name, value } : (value.build {
          interfaces = (nixpkgs.lib.filter (iface: iface.driver == name) interfaces);
        }).config.systemd) (nixpkgs.lib.attrsets.attrsToList foxDenLib.hosts.drivers))
        ++ [{
          # Configure each host's NetNS
          services = (nixpkgs.lib.attrsets.listToAttrs (map (host: let
            ipCmd = eSA "${pkgs.iproute2}/bin/ip";
            netnsExecCmd = "${ipCmd} netns exec ${eSA host.namespace}";
            ipInNsCmd = "${netnsExecCmd} ${ipCmd}";

            renderRoute = (dev: route: "${ipInNsCmd} route add " + (if route.Destination != null then eSA route.Destination else "default") + (if route.Gateway != null then " via ${eSA route.Gateway}" else " dev ${eSA dev}"));

            mkHooks = (interface: let
              ifaceDriver = foxDenLib.hosts.drivers.${interface.driver};
              serviceInterface = (ifaceDriver.serviceInterface or (interface: "host-${interface.suffix}")) interface;

              driverRunParams = { inherit ipCmd ipInNsCmd netnsExecCmd serviceInterface interface; };
              hooks = ifaceDriver.hooks driverRunParams;

              sysctlsRaw = {
                "net.ipv6.conf.INTERFACE.accept_ra" = "1";
                "net.ipv4.ip_unprivileged_port_start" = "1";
              } // interface.sysctls;

              sysctls = nixpkgs.lib.concatStringsSep "\n" (map
                ({ name, value }: "${nixpkgs.lib.replaceString "INTERFACE" serviceInterface name} = ${value}")
                (nixpkgs.lib.attrsets.attrsToList sysctlsRaw)
              );
            in
            {
              start =
                hooks.start
                ++ [ "${ipCmd} link set ${eSA serviceInterface} netns ${eSA host.namespace}" ]
                ++ (map (addr:
                      "${ipInNsCmd} addr add ${eSA addr} dev ${eSA serviceInterface}")
                      interface.addresses)
                ++ [
                  "${netnsExecCmd} ${pkgs.sysctl}/bin/sysctl -p ${pkgs.writers.writeText "sysctls" sysctls}"
                ] ++ (hooks.setMac or [
                  "${ipInNsCmd} link set ${eSA serviceInterface} address ${eSA interface.mac}"
                ]) ++ [
                  "${ipInNsCmd} link set ${eSA serviceInterface} up"
                ]
                ++ (map (renderRoute serviceInterface) interface.routes);

              stop =
                [ "${ipInNsCmd} link set ${eSA serviceInterface} down" ]
                ++ hooks.stop;
            });
          in
          {
            name = (nixpkgs.lib.strings.removeSuffix ".service" host.unit);
            value = let
              ifaceHooks = map mkHooks (nixpkgs.lib.filter (iface: iface.host.name == host.name) interfaces);
              getHook = sub: nixpkgs.lib.flatten (map (cfg: cfg.${sub}) ifaceHooks);
            in {
              description = "NetNS ${host.namespace}";
              after = [ "network-pre.target" ];
              restartTriggers = [ (builtins.concatStringsSep " " host.nameservers) ];

              unitConfig = {
                StopWhenUnneeded = true;
              };

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;

                ExecStart = [
                    "-${ipCmd} netns del ${eSA host.namespace}"
                    "${ipCmd} netns add ${eSA host.namespace}"
                    "${ipInNsCmd} addr add 127.0.0.1/8 dev lo"
                    "${ipInNsCmd} addr add ::1/128 dev lo noprefixroute"
                    "${ipInNsCmd} link set lo up"
                  ]
                  ++ (getHook "start");

                ExecStop =
                  (getHook "stop")
                  ++ [
                    "${ipCmd} netns del ${eSA host.namespace}"
                  ];
              };
            };
          }) hosts));
        }
      ]);
    };
  });
}
