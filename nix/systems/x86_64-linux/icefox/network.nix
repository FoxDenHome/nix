{ config, foxDenLib, ... }:
let
  ifcfg-s2s = {
    addresses = [
      "10.99.10.2/16"
      "fd2c:f4cb:63be::a63:a02/112"
    ];
    interface = "br-s2s";
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

  mkHost = foxDenLib.hosts.helpers.hetzner.mkHost ifcfg ifcfg-s2s;
  mkV6Host = foxDenLib.hosts.helpers.hetzner.mkV6Host ifcfg ifcfg-s2s;
  mkMinHost = foxDenLib.hosts.helpers.hetzner.mkMinHost ifcfg ifcfg-s2s;
in
{
  config = {
    lib.system = {
      inherit ifcfg ifcfg-s2s mkHost mkV6Host mkMinHost;
    };

    virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

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

    networking.nftables.tables = {
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
            tcp dport { 80, 443 } dnat to 10.99.12.2 comment "foxIngress"
            udp dport { 443 } dnat to 10.99.12.2 comment "foxIngress"

            tcp dport { 5222, 5223, 5269 } dnat to 10.99.12.4 comment "Prosody"

            tcp dport { 22000 } dnat to 10.99.12.6 comment "Syncthing"
            udp dport { 22000 } dnat to 10.99.12.6 comment "Syncthing"
          }
        '';
        family = "ip";
      };
    };

    networking.nftables.tables = {
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

    systemd.network.netdevs.br-routed = {
      netdevConfig = {
        Name = "br-routed";
        Kind = "bridge";
        MACAddress = "e6:21:ff:00:00:01";
      };

      bridgeConfig = {
        VLANFiltering = false;
      };
    };

    systemd.network.networks."40-${ifcfg.interface}-root" = {
      name = phyIface;
      bridge = [ifcfg.interface];
    };

    systemd.network.networks."30-${ifcfg-s2s.interface}" = {
      name = ifcfg-s2s.interface;
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

    systemd.network.networks."30-br-routed" = {
      name = "br-routed";
      address = [
        "2a01:4f9:2b:1a42::1:1/112"
      ];

      networkConfig = {
        IPv6Forwarding = true;

        DHCP = "no";
        IPv6AcceptRA = false;
      };
    };

    systemd.network.netdevs."${ifcfg-s2s.interface}" = {
      netdevConfig = {
        Name = ifcfg-s2s.interface;
        Kind = "bridge";
      };

      bridgeConfig = {
        VLANFiltering = false;
      };
    };

    foxDen.services = {
      trustedProxies = [
        "10.1.0.0/23"
        "10.2.0.0/23"
        "10.3.0.0/23"
        "10.4.0.0/23"
        "10.5.0.0/23"
        "10.6.0.0/23"
        "10.7.0.0/23"
        "10.8.0.0/23"
        "10.9.0.0/23"
        "10.99.12.2/32"
      ];

      wireguard."wg-s2s" = config.lib.foxDen.sops.mkIfAvailable {
        host = "";
        interface = {
          ips = ifcfg-s2s.addresses;
          listenPort = 13232;
          peers = [
            {
              allowedIPs = [ "10.99.1.1/32" "fd2c:f4cb:63be::a63:101/128" "10.0.0.0/8" "fd2c:f4cb:63be::/60" ];
              endpoint = "router.foxden.network:13232";
              persistentKeepalive = 25;
              publicKey = "nCTAIMDv50QhwjCw72FwP2u2pKGMcqxJ09DQ9wJdxH0=";
            }
            {
              allowedIPs = [ "10.99.10.1/32" "fd2c:f4cb:63be::a63:a01/128" ];
              endpoint = "redfox.doridian.net:13232";
              persistentKeepalive = 25;
              publicKey = "s1COjkpfpzfQ05ZLNLGQrlEhomlzwHv+APvUABzbSh8=";
            }
            {
              allowedIPs = [ "10.99.1.2/32" "fd2c:f4cb:63be::a63:102/128" ];
              endpoint = "router-backup.foxden.network:13232";
              persistentKeepalive = 25;
              publicKey = "8zUl7b1frvuzcBrIA5lNsegzzyAOniaZ4tczSdoqcWM=";
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

    foxDen.hosts.gateway = "icefox";
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
        interfaces.s2s = mkIntf ifcfg-s2s.addresses;
      };
    };
  };
}
