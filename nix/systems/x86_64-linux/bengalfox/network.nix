{ foxDenLib, ... }:
let
  ifcfg = {
    addresses = [
      "10.2.10.9/16"
      "fd2c:f4cb:63be:2::a09/64"
    ];
    routes = foxDenLib.hosts.helpers.lan.mkRoutes 2;
    nameservers = foxDenLib.hosts.helpers.lan.mkNameservers 2;
    phyIface = "ens1f0np0";
    phyPvid = 2;
    defaultDriver = "sriov";
  };
in
{
  lib.foxDenSys.mkVlanHost = foxDenLib.hosts.helpers.lan.mkVlanHost ifcfg;

  foxDen.hosts.index = 1;
  foxDen.hosts.gateway = "router";

  systemd.network.networks."30-${ifcfg.phyIface}" = {
    name = ifcfg.phyIface;
    routes = ifcfg.routes;
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = true;
    };
  };
  #boot.initrd.systemd.network.networks."30-${ifcfg.phyIface}" = config.systemd.network.networks."30-${ifcfg.phyIface}";

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
