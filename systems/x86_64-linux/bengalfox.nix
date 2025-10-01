{ config, ... }:
let
  ifcfg = {
    addresses = [
      "10.2.11.1/16"
      "fd2c:f4cb:63be:2::b01/64"
    ];
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "10.2.0.1"; }
    ];
    nameservers = [ "10.2.0.53" ];
    interface = "br-default";
  };

  rootInterface = "ens1f0np0";
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = false;
  foxDen.boot.secure = false;

  system.stateVersion = "25.05";

  boot.initrd.luks.devices.nixroot.device = "/dev/md0";
  boot.swraid = {
    enable = true;
    mdadmConf = [
      "ARRAY /dev/md0 metadata=1.2 UUID=a84487b7:a5d11a87:32de3997:dacc0654"
      "ARRAY /dev/md1 metadata=1.2 UUID=115c644c:fcb4a527:5d784e0c:9c379b03"
    ];
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
    { device = "/dev/nvme1n1p1";
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

  foxDen.hosts.hosts = {
    bengalfox = {
      nameservers = ifcfg.nameservers;
      interfaces.default = {
        dns = {
          name = "bengalfox";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = ifcfg.addresses;
        routes = ifcfg.routes;
      };
    };
  };
}
