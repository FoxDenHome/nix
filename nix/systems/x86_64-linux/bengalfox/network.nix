{ foxDenLib, config, ... }:
let
  ifcfg = {
    addresses = [
      "10.2.10.9/16"
      "fd2c:f4cb:63be:2::a09/64"
    ];
    routes = foxDenLib.hosts.helpers.lan.mkRoutes 2;
    nameservers = foxDenLib.hosts.helpers.lan.mkNameservers 2;
    interface = "br-default";
    mac = "e8:eb:d3:08:d2:98";
  };
in
{
  config = {
    lib.foxDenSys.mkVlanHost = foxDenLib.hosts.helpers.lan.mkVlanHost ifcfg;

    virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];
    foxDen.hosts.index = 1;
    foxDen.hosts.gateway = "router";

    systemd.network.netdevs."${ifcfg.interface}" = {
      netdevConfig = {
        Name = ifcfg.interface;
        Kind = "bridge";
        MACAddress = ifcfg.mac;
      };

      bridgeConfig = {
        VLANFiltering = true;
      };
    };

    systemd.network.networks."30-${ifcfg.interface}" = {
      name = ifcfg.interface;
      routes = ifcfg.routes;
      address = ifcfg.addresses;
      dns = ifcfg.nameservers;

      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = true;
      };

      bridgeVLANs = [{
        PVID = 2;
        EgressUntagged = 2;
        VLAN = "2";
      }];
    };

    systemd.network.networks."40-${ifcfg.interface}-root" = {
      name = "ens1f0np0";
      bridge = [ifcfg.interface];

      bridgeVLANs = [{
        PVID = 2;
        EgressUntagged = 2;
        VLAN = "1-10";
      }];
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
      ];

      wireguard."wg-deluge" = config.lib.foxDen.sops.mkIfAvailable {
        host = "deluge"; # solid snake
        interface = {
          ips = [ "10.70.175.10/32" "fc00:bbbb:bbbb:bb01::7:af09/128" ];
          peers = [
            {
              allowedIPs = [ "0.0.0.0/0" "::/0" "10.64.0.1/32" ];
              endpoint = "23.234.81.127:51820";
              persistentKeepalive = 25;
              publicKey = "G6+A375GVmuFCAtvwgx3SWCWhrMvdQ+cboXQ8zp2ang=";
            }
          ];
        };
      };
    };

    foxDen.hosts.hosts = {
      bengalfox = {
        interfaces.default = {
          driver = "null";
          dns = {
            name = "bengalfox";
            zone = "foxden.network";
          };
          addresses = ifcfg.addresses;
        };
      };
    };
  };
}
