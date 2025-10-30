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
    phyIface = "ens1f0np0";
    phyPvid = 2;
    mac = "e8:eb:d3:08:d2:98";
  };
in
{
  lib.foxDenSys.mkVlanHost = foxDenLib.hosts.helpers.lan.mkVlanHost ifcfg;

  foxDen.hosts.index = 1;
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

  foxDen.services = {
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
          name = "bengalfox.foxden.network";
        };
        addresses = ifcfg.addresses;
      };
    };
  };
}
