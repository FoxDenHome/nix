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

  phyIface = "enp1s0f1";
in
{
  lib.foxDenSys.mkVlanHost = foxDenLib.hosts.helpers.lan.mkVlanHost ifcfg;

  foxDen.hosts.index = 2;
  foxDen.hosts.gateway = "router";
  virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

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
  #boot.initrd.systemd.network.networks."30-${phyIface}" = config.systemd.network.networks."30-${ifcfg.interface}" // { name = phyIface; };

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
    name = phyIface;
    bridge = [ifcfg.interface];

    bridgeVLANs = [{
      PVID = 2;
      EgressUntagged = 2;
      VLAN = "1-10";
    }];
  };

  foxDen.hosts.hosts = {
    islandfox = {
      interfaces.default = {
        driver = "null";
        dns = {
          name = "islandfox.foxden.network";
        };
        addresses = ifcfg.addresses;
      };
    };
  };
}
