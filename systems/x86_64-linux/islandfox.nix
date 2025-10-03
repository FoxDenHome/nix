{ config, ... }:
let
  mkNameservers = (vlan: [
    "10.${builtins.toString vlan}.0.53"
    "fd2c:f4cb:63be:${builtins.toString vlan}\::35"
  ]);
  mkRoutes = (vlan: [
    { Destination = "0.0.0.0/0"; Gateway = "10.${builtins.toString vlan}.0.1"; }
    { Destination = "::/0"; Gateway = "fd2c:f4cb:63be:${builtins.toString vlan}\::1"; }
  ]);

  ifcfg = {
    addresses = [
      "10.2.10.11/16"
      "fd2c:f4cb:63be:2::a0b/64"
    ];
    routes = mkRoutes 2;
    nameservers = mkNameservers 2;
    interface = "br-default";
  };

  rootInterface = "enp1s0f1";
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = false;
  foxDen.boot.secure = false;

  system.stateVersion = "25.05";

  boot.swraid = {
    enable = true;
    mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=660f8703:f7ec5be9:b586b082:ce74a589";
  };

  boot.initrd.luks.devices = {
    nixroot = {
      device = "/dev/md0";
      allowDiscards = true;
    };
  };

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/nixroot";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/boot2" =
    { device = "/dev/sda1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = ifcfg.routes;
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };

    # bridgeVLANs = [{
    #   PVID = 2;
    #   EgressUntagged = 2;
    #   VLAN = "1-10";
    # }];
  };

  systemd.network.netdevs."${ifcfg.interface}" = {
    netdevConfig = {
      Name = ifcfg.interface;
      Kind = "bridge";
    };

    bridgeConfig = {
      VLANFiltering = true;
    };
  };

  systemd.network.networks."40-${ifcfg.interface}-${rootInterface}" = {
      name = rootInterface;
      bridge = [ifcfg.interface];
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
  };

  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
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

    backupmgr.enable = true;
  };

  foxDen.hosts.hosts = let
    driver = "bridge";
    mkDriverOpts = (vlan: {
      bridge = ifcfg.interface;
      vlan = vlan;
    });

    mkVlanIntf = (vlan: cfg: {
      inherit driver;
      driverOpts = mkDriverOpts vlan;
      routes = mkRoutes vlan;
    } // cfg);

    mkVlanHost = (vlan: cfg: {
      nameservers = mkNameservers vlan;
      interfaces.default = mkVlanIntf vlan cfg;
    });
  in {
    islandfox = {
      interfaces.default = {
        dns = {
          name = "islandfox";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = ifcfg.addresses;
      };
    };
  };
}
