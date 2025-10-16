{ foxDenLib, ... }:
let
  ifcfg = {
    addresses = [
      "10.2.10.11/16"
      "fd2c:f4cb:63be:2::a0b/64"
    ];
    routes = foxDenLib.hosts.helpers.lan.mkRoutes 2;
    nameservers = foxDenLib.hosts.helpers.lan.mkNameservers 2;
    interface = "br-default";
    mac = "04:7b:cb:44:c0:dd";
  };
in
{
  config = {
    lib.mkVlanHost = foxDenLib.hosts.helpers.lan.mkVlanHost ifcfg;

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

    systemd.network.networks."40-${ifcfg.interface}-root" = {
      name = "enp1s0f1";
      bridge = [ifcfg.interface];

      bridgeVLANs = [{
        PVID = 2;
        EgressUntagged = 2;
        VLAN = "1-10";
      }];
    };

    virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

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
    };
    foxDen.hosts.index = 2;
    foxDen.hosts.gateway = "router";
    foxDen.hosts.hosts = {
      islandfox = {
        interfaces.default = {
          driver = "null";
          dns = {
            name = "islandfox";
            zone = "foxden.network";
          };
          addresses = ifcfg.addresses;
        };
      };
    };
  };
}
