{ config, lib, foxDenLib, firewall, ... }:
let
  ifcfg-foxden = {
    addresses = [
      "10.99.10.2/16"
      "fd2c:f4cb:63be::a63:a02/112"
    ];
    interface = "br-foxden";
  };
  ifcfg = {
    addresses = [
      "95.216.116.140/26"
      "2a01:4f9:2b:1a42::0:1/112"
    ];
    nameservers = [
      "213.133.98.98"
      "213.133.98.99"
      "213.133.98.100"
    ];
    mac = "fc:34:97:68:1e:07";
    interface = "br-default";
  };

  phyIface = "enp7s0";
  routedInterface = "br-routed";

  mkMinHost = (iface: {
    inherit (ifcfg) nameservers;
    interfaces.default = iface // {
      sysctls = {
        "net.ipv6.conf.INTERFACE.accept_ra" = "0";
      } // (iface.sysctls or {});
      addresses = lib.filter (ip: !(foxDenLib.util.isPrivateIP ip)) iface.addresses;
      driver = "bridge";
      snirouter.enable = false;
      driverOpts.bridge = lib.mkDefault ifcfg.interface;
      driverOpts.vlan = 0;
      routes = [ ];
    };
    interfaces.foxden = iface // {
      sysctls = {
        "net.ipv6.conf.INTERFACE.accept_ra" = "0";
      } // (iface.sysctls or {});
      mac = null;
      addresses = lib.filter (foxDenLib.util.isPrivateIP) iface.addresses;
      driver = "bridge";
      driverOpts.bridge = ifcfg-foxden.interface;
      driverOpts.vlan = 0;
      routes = [
        { Destination = "10.0.0.0/8"; Gateway = "10.99.12.1"; }
        { Destination = "fd2c:f4cb:63be::/60"; Gateway = "fd2c:f4cb:63be::a63:c01"; }
      ];
    };
  });
in
{
  lib.foxDenSys = {
    inherit routedInterface mkMinHost;
    mkHost = ifcfg: ifcfg-foxden: iface: lib.mkMerge [
      (mkMinHost ifcfg ifcfg-foxden iface)
      {
        interfaces.default.routes = [
          { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
          { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::0:1"; }
        ];
      }
    ];
    mkV6Host = iface: lib.mkMerge [
      (mkMinHost ifcfg ifcfg-foxden ({ mac = null; } // iface))
      {
        interfaces.default = {
          dns.auxAddresses = [ "95.216.116.140" ];
          routes = [
            { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::1:1"; }
          ];
          driverOpts.bridge = routedInterface;
        };
        interfaces.foxden.routes = [
          { Destination = "0.0.0.0/0"; Gateway = "10.99.12.1"; }
        ];
      }
    ];
  };

  foxDen.hosts.index = 3;
  foxDen.hosts.gateway = "icefox";
  virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ifcfg-foxden.interface routedInterface ];

  # We don't firewall on servers, so only use port forward type rules
  networking.nftables.tables = let
    firewallRules = firewall."${config.foxDen.hosts.gateway}";
    portForwardrules = lib.lists.filter (rule: rule.action == "dnat" && rule.chain == "prerouting" && rule.table == "nat") firewallRules;

    sharedIPRules = map (rule: "  ${rule.protocol} dport ${builtins.toString rule.dstport} dnat to ${rule.toAddresses} comment \"${rule.comment}\"") portForwardrules;
  in {
    nat = {
      content = ''
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ip saddr 10.99.12.0/24 oifname "${ifcfg.interface}" snat to 95.216.116.140
        }

        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          ip daddr 95.216.116.140/32 iifname "${ifcfg.interface}" jump sharedip
        }

        chain sharedip {
        ${builtins.concatStringsSep "\n" sharedIPRules}
        }
      '';
      family = "ip";
    };
    filter = {
      content = ''
        chain forward {
          type filter hook forward priority 0; policy accept;
          oifname "${phyIface}" ether saddr & ff:ff:00:00:00:00 == e6:21:00:00:00:00 drop
        }
      '';
      family = "bridge";
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
    "net.ipv6.conf.default.forwarding" = "1";
  };

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
      { Destination = "::/0"; Gateway = "fe80::1"; }
    ];
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;

      DHCP = "no";
      IPv6AcceptRA = true;
    };
  };

  systemd.network.netdevs."${ifcfg.interface}" = {
    netdevConfig = {
      Name = ifcfg.interface;
      Kind = "bridge";
      MACAddress = ifcfg.mac;
    };

    bridgeConfig = {
      VLANFiltering = false;
    };
  };

  systemd.network.netdevs."${routedInterface}" = {
    netdevConfig = {
      Name = routedInterface;
      Kind = "bridge";
      MACAddress = config.lib.foxDen.mkHashMac "000001";
    };

    bridgeConfig = {
      VLANFiltering = false;
    };
  };

  systemd.network.networks."40-${ifcfg.interface}-root" = {
    name = phyIface;
    bridge = [ifcfg.interface];
  };

  systemd.network.networks."30-${ifcfg-foxden.interface}" = {
    name = ifcfg-foxden.interface;
    address = [
      "10.99.12.1/24"
      "fd2c:f4cb:63be::a63:c01/120"
    ];

    networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;

      DHCP = "no";
      IPv6AcceptRA = false;
    };
  };

  systemd.network.networks."30-${routedInterface}" = {
    name = routedInterface;
    address = [
      "2a01:4f9:2b:1a42::1:1/112"
    ];

    networkConfig = {
      IPv6Forwarding = true;

      DHCP = "no";
      IPv6AcceptRA = false;
    };
  };

  systemd.network.netdevs."${ifcfg-foxden.interface}" = {
    netdevConfig = {
      Name = ifcfg-foxden.interface;
      Kind = "bridge";
    };

    bridgeConfig = {
      VLANFiltering = false;
    };
  };

  foxDen.services = {
    wireguard."wg-foxden" = config.lib.foxDen.sops.mkIfAvailable {
      host = "";
      interface = {
        ips = ifcfg-foxden.addresses;
        listenPort = 13232;
        peers = [
          {
            allowedIPs = [ "10.99.1.1/32" "fd2c:f4cb:63be::a63:101/128" "10.0.0.0/8" "fd2c:f4cb:63be::/60" ];
            endpoint = "v4-router.foxden.network:13232";
            persistentKeepalive = 25;
            publicKey = "nCTAIMDv50QhwjCw72FwP2u2pKGMcqxJ09DQ9wJdxH0=";
          }
          {
            allowedIPs = [ "10.99.1.2/32" "fd2c:f4cb:63be::a63:102/128" ];
            endpoint = "v4-router-backup.foxden.network:13232";
            persistentKeepalive = 25;
            publicKey = "8zUl7b1frvuzcBrIA5lNsegzzyAOniaZ4tczSdoqcWM=";
          }
          {
            allowedIPs = [ "10.99.10.1/32" "fd2c:f4cb:63be::a63:a01/128" ];
            endpoint = "redfox.doridian.net:13232";
            persistentKeepalive = 25;
            publicKey = "s1COjkpfpzfQ05ZLNLGQrlEhomlzwHv+APvUABzbSh8=";
          }
        ];
      };
    };
  };

  foxDen.dns.records = [
    {
      zone = "doridian.net";
      name = "v4-icefox";
      type = "A";
      ttl = 3600;
      value = "95.216.116.140";
      horizon = "external";
    }
    {
      zone = "doridian.net";
      name = "v4-icefox";
      type = "CNAME";
      ttl = 3600;
      value = "icefox.foxden.network.";
      horizon = "internal";
    }
  ];

  # Due to Hetzner routing, we have two IPv6 subnets
  # - 2a01:4f9:2b:1a42::0:/112 for hosts which have public IPv4
  # - 2a01:4f9:2b:1a42::1:/112 for hosts without public IPv4 (routed out via 95.216.116.140)
  foxDen.hosts.hosts = {
    icefox = let
      mkIntf = addresses: {
        driver = "null";
        dns = {
          name = "icefox";
          zone = "foxden.network";
        };
        cnames = [
          {
            name = "icefox";
            zone = "doridian.net";
          }
        ];
        inherit addresses;
      };
    in {
      inherit (ifcfg) nameservers;
      interfaces.default = mkIntf ifcfg.addresses;
      interfaces.foxden = mkIntf ifcfg-foxden.addresses;
    };
  };
}
