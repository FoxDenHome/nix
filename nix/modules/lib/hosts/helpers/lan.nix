{ ... }:
rec {
  mkNameservers = (vlan: [
    "10.${builtins.toString vlan}.0.53"
    "fd2c:f4cb:63be:${builtins.toString vlan}\::35"
  ]);

  mkRoutes = (vlan: [
    { Destination = "0.0.0.0/0"; Gateway = "10.${builtins.toString vlan}.0.1"; }
  ]);

  mkVlanHost = (ifcfg: vlan: cfg: let
    driver = ifcfg.defaultDriver or "bridge";
  in {
    nameservers = mkNameservers vlan;
    interfaces.default = {
      inherit driver;
      driverOpts = if driver == "sriov" then {
        root = ifcfg.phyIface;
        rootPvid = ifcfg.phyPvid;
        vlan = vlan;
      } else if driver == "bridge" then {
        bridge = ifcfg.interface;
        vlan = vlan;
      } else {};
      routes = mkRoutes vlan;
    } // cfg;
  });
}
