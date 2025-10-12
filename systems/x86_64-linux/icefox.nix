{ config, foxDenLib, lib, ... }:
let
  ifcfg-s2s = {
    addresses = [
      "10.99.10.2/16"
      "fd2c:f4cb:63be::a63:a02/112"
    ];
    interface = "br-s2s";
  };
  ifcfg = {
    addresses = [
      "95.216.116.140/26"
      "2a01:4f9:2b:1a42::2/64"
    ];
    nameservers = [
      "213.133.98.98"
      "213.133.98.99"
      "213.133.98.100"
    ];
    macAddress = "fc:34:97:68:1e:07";
    interface = "br-default";
  };

  phyIface = "enp7s0";
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = false;
  foxDen.boot.secure = false;

  system.stateVersion = "25.05";

  services.timesyncd.servers = ["ntp1.hetzner.de" "ntp2.hetzner.com" "ntp3.hetzner.net"];

  boot.swraid = {
    enable = true;
    mdadmConf = [
      "ARRAY /dev/md0 metadata=1.2 UUID=f8fef6b4:264144e8:1d611b0a:ba263ab2"
    ];
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
    { device = "/dev/nvme1n1p1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/mnt/ztank" =
    { device = "ztank/ROOT";
      fsType = "zfs";
    };

  sops.secrets."zfs-ztank.key" = config.lib.foxDen.sops.mkIfAvailable {
    format = "binary";
    sopsFile = ../../secrets/zfs-ztank.key;
  };

  virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
    ];
    address = ifcfg.addresses ++ [
      "2a01:4f9:2b:1a42:ffff::1/64"
    ];
    dns = ifcfg.nameservers;

    networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;
      IPv4ProxyARP = true;
      IPv6ProxyNDP = true;

      IPv6ProxyNDPAddress = ["2a01:4f9:2b:1a42:ffff::2"];

      DHCP = "no";
      IPv6AcceptRA = true;
    };
  };

  networking.nftables.tables = {
    filter = {
      content = ''
        chain forward {
          type filter hook forward priority 0;
          ip accept
          arp accept
          iif ${phyIface} accept
          not oif ${phyIface} accept
          ether saddr ${ifcfg.macAddress} accept
          drop
        }
      '';
      family = "bridge";
    };
  };

  systemd.network.netdevs."${ifcfg.interface}" = {
    netdevConfig = {
      Name = ifcfg.interface;
      Kind = "bridge";
      MACAddress = ifcfg.macAddress;
    };

    bridgeConfig = {
      VLANFiltering = false;
    };
  };

  systemd.network.networks."40-${ifcfg.interface}-root" = {
    name = phyIface;
    bridge = [ifcfg.interface];
  };

  systemd.network.networks."30-${ifcfg-s2s.interface}" = {
    name = ifcfg-s2s.interface;
    address = [
      "10.99.12.1/24"
      "fd2c:f4cb:63be::a63:c01/120"
    ];

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };
  };

  systemd.network.netdevs."${ifcfg-s2s.interface}" = {
    netdevConfig = {
      Name = ifcfg-s2s.interface;
      Kind = "bridge";
    };

    bridgeConfig = {
      VLANFiltering = false;
    };
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
      # TODO: IP of snirouter on 10.99 here
    ];

    backupmgr.enable = true;
    gitbackup = {
      enable = true;
      host = "";
    };
  };

  foxDen.hosts.hosts = let
    mkHost = iface: {
      inherit (ifcfg) nameservers;
      interfaces.default = {
        inherit (iface) dns macAddress;
        addresses = lib.filter (ip: !(foxDenLib.util.isPrivateIP ip)) iface.addresses;
        driver = "hetzner";
        driverOpts = {
          network = ifcfg.interface;
          bridge = ifcfg.interface;
        };
        routes = [
          { Destination = "2a01:4f9:2b:1a42::2"; }
          { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
          { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::2"; }
        ];
      };
      interfaces.s2s = {
        inherit (iface) dns;
        addresses = lib.filter (foxDenLib.util.isPrivateIP) iface.addresses;
        driver = "bridge";
        driverOpts = {
          bridge = ifcfg-s2s.interface;
        };
        routes = [
          { Destination = "10.0.0.0/8"; Gateway = "10.99.12.1"; }
          { Destination = "fd2c:f4cb:63be::/60"; Gateway = "fd2c:f4cb:63be::a63:c01"; }
        ];
      };
    };
  in
  {
    icefox = {
      inherit (ifcfg) nameservers;
      interfaces.default = {
        driver = "null";
        dns = {
          name = "icefox";
          zone = "foxden.network";
        };
        addresses = ifcfg.addresses;
      };
      interfaces.s2s = {
        driver = "null";
        dns = {
          name = "icefox";
          zone = "foxden.network";
        };
        addresses = ifcfg-s2s.addresses;
      };
    };
    mirror = mkHost {
      dns = {
        name = "mirror-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "95.216.116.139/26"
        "2a01:4f9:2b:1a42::3/64"
      ];
      macAddress = "TODO";
    };
    icefox-http = mkHost {
      dns = {
        name = "icefox-http";
        zone = "foxden.network";
      };
      addresses = [
        "95.216.116.180/26"
        "2a01:4f9:2b:1a42::8/64"
      ];
      macAddress = "00:50:56:00:81:B8";
    };
  };
}
