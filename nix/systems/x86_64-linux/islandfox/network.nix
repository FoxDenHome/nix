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
    phyIface = "enp1s0f1";
    phyPvid = 2;
    mtu = 9000;
    mac = "04:7b:cb:44:c0:dd";
  };
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
      PVID = ifcfg.phyPvid;
      EgressUntagged = ifcfg.phyPvid;
      VLAN = builtins.toString ifcfg.phyPvid;
    }];

    linkConfig = {
      MTUBytes = ifcfg.mtu;
    };
  };
  #boot.initrd.systemd.network.networks."30-${ifcfg.phyIface}" = config.systemd.network.networks."30-${ifcfg.interface}" // { name = ifcfg.phyIface; };

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
    name = ifcfg.phyIface;
    bridge = [ifcfg.interface];

    bridgeVLANs = [{
      PVID = ifcfg.phyPvid;
      EgressUntagged = ifcfg.phyPvid;
      VLAN = "1-10";
    }];
  };

  # BEGIN: Network to avoid network hop for talking to local Kanidm
  systemd.network.netdevs."${ifcfg.interface}.1" = {
    netdevConfig = {
      Name = "${ifcfg.interface}.1";
      Kind = "vlan";
    };

    vlanConfig = {
      Id = 1;
    };
  };
  systemd.network.networks."30-${ifcfg.interface}.1" = {
    name = "${ifcfg.interface}.1";
    routes = [ ];
    address = [ ];

    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };

    dhcpV4Config = {
      UseDNS = false;
      UseRoutes = false;
      UseNTP = false;
      UseDomains = false;
      UseHostname = false;
      UseGateway = false;
    };

    dhcpV6Config = {
      UseDNS = false;
      UseNTP = false;
      UseDomains = false;
      UseHostname = false;
    };

    ipv6AcceptRAConfig = {
      UseDomains = false;
      UseDNS = false;
      UseGateway = false;
      UseRoutePrefix = false;
    };

    linkConfig = {
      MTUBytes = ifcfg.mtu;
    };
  };
  # END: Network to avoid network hop for talking to local Kanidm

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
