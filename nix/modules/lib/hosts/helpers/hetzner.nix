{ nixpkgs, foxDenLib, ... } :
let
  lib = nixpkgs.lib;

  mkMinHost = (ifcfg: ifcfg-foxden: iface: {
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

  routedInterface = "br-routed";
in
{
  inherit mkMinHost routedInterface;

  mkHost = (ifcfg: ifcfg-foxden: iface: lib.mkMerge [
    (mkMinHost ifcfg ifcfg-foxden iface)
    {
      interfaces.default.routes = [
        { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
        { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::0:1"; }
      ];
    }
  ]);

  mkV6Host = (ifcfg: ifcfg-foxden: iface: lib.mkMerge [
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
  ]);
}
