{ ... } :
rec {
  mkNameservers = (vlan: [
    "10.${builtins.toString vlan}.0.53"
    "fd2c:f4cb:63be:${builtins.toString vlan}\::35"
  ]);

  mkRoutes = (vlan: [
    { Destination = "0.0.0.0/0"; Gateway = "10.${builtins.toString vlan}.0.1"; }
  ]);

  mkVlanHost = (ifcfg: vlan: cfg: {
    nameservers = mkNameservers vlan;
    interfaces.default = cfg // {
      driver = "bridge";
      driverOpts = {
        bridge = ifcfg.interface;
        vlan = vlan;
      };
      routes = mkRoutes vlan;
    };
  });
}
