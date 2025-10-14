{ config, foxDenLib, pkgs, lib, ... }:
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
    mac = "fc:34:97:68:1e:07";
    interface = "br-default";
  };

  phyIface = "enp7s0";
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = true;
  foxDen.boot.secure = true;

  system.stateVersion = "25.05";

  services.timesyncd.servers = ["ntp1.hetzner.de" "ntp2.hetzner.com" "ntp3.hetzner.net"];

  boot.swraid = {
    enable = true;
    mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=f8fef6b4:264144e8:1d611b0a:ba263ab2";
  };

  boot.initrd.luks.devices = {
    nixroot = {
      device = "/dev/md0";
      allowDiscards = true;
    };
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/nixroot";
    fsType = "xfs";
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "nofail" ];
  };

  fileSystems."/boot2" = {
    device = "/dev/nvme1n1p1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "nofail" ];
  };

  fileSystems."/mnt/ztank" = {
    device = "ztank/ROOT";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local" = {
    device = "ztank/ROOT/local";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/backups" = {
    device = "ztank/ROOT/local/backups";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/backups/arcticfox" = {
    device = "ztank/ROOT/local/backups/arcticfox";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/mirror" = {
    device = "ztank/ROOT/local/mirror";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/restic" = {
    device = "ztank/ROOT/local/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/torrent" = {
    device = "ztank/ROOT/local/torrent";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/usenet" = {
    device = "ztank/ROOT/local/usenet";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/restic" = {
    device = "ztank/ROOT/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/users" = {
    device = "ztank/ROOT/users";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/users/kilian" = {
    device = "ztank/ROOT/users/kilian";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd" = {
    device = "ztank/ROOT/zhdd";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/restic" = {
    device = "ztank/ROOT/zhdd/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/e621" = {
    device = "ztank/ROOT/zhdd/e621";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/furaffinity" = {
    device = "ztank/ROOT/zhdd/furaffinity";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/kiwix" = {
    device = "ztank/ROOT/zhdd/kiwix";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nas" = {
    device = "ztank/ROOT/zhdd/nas";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nashome" = {
    device = "ztank/ROOT/zhdd/nashome";
    fsType = "zfs";
    options = [ "nofail" ];
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
      IPv6Forwarding = true;
      IPv6ProxyNDP = true;

      IPv6ProxyNDPAddress = [
        "2a01:4f9:2b:1a42:ffff::2" # arcticfox
      ];

      DHCP = "no";
      IPv6AcceptRA = true;
    };
  };

  # networking.nftables.tables = {
  #   filter = {
  #     content = ''
  #       chain forward {
  #         type filter hook forward priority 0;
  #         ip accept
  #         arp accept
  #         iif ${phyIface} accept
  #         not oif ${phyIface} accept
  #         ether saddr ${ifcfg.mac} accept
  #         drop
  #       }
  #     '';
  #     family = "bridge";
  #   };
  # };

  systemd.network.netdevs."${ifcfg.interface}" = {
    netdevConfig = {
      Name = ifcfg.interface;
      Kind = "bridge";
      MACAddress = ifcfg.mac;
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
      IPv4Forwarding = true;
      IPv6Forwarding = true;

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
      "10.99.12.2/32"
    ];

    wireguard."wg-deluge" = {
      host = "deluge";
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
    wireguard."wg-s2s" = {
      host = "";
      interface = {
        ips = [ "10.99.10.2/32" ];
        peers = [
          {
            allowedIPs = [ "10.99.1.1/32" "fd2c:f4cb:63be::a63:101/128" "10.0.0.0/8" "fd2c:f4cb:63be::/60" ];
            endpoint = "router.foxden.network:13231";
            persistentKeepalive = 25;
            publicKey = "nCTAIMDv50QhwjCw72FwP2u2pKGMcqxJ09DQ9wJdxH0=";
          }
          {
            allowedIPs = [ "10.99.10.1/32" "fd2c:f4cb:63be::a63:a01/128" ];
            endpoint = "redfox.doridian.net:13231";
            persistentKeepalive = 25;
            publicKey = "s1COjkpfpzfQ05ZLNLGQrlEhomlzwHv+APvUABzbSh8=";
          }
          {
            allowedIPs = [ "10.99.1.2/32" "fd2c:f4cb:63be::a63:102/128" ];
            endpoint = "router-backup.foxden.network:13231";
            persistentKeepalive = 25;
            publicKey = "8zUl7b1frvuzcBrIA5lNsegzzyAOniaZ4tczSdoqcWM=";
          }
        ];
      };
    };

    backupmgr.enable = true;
    gitbackup = {
      enable = true;
      host = "";
    };
    mirror = {
      enable = true;
      host = "mirror";
      tls = true;
      dataDir = "/mnt/ztank/local/mirror";
      archMirrorId = "23m.com";
      sources.archlinux = {
        rsyncUrl = "rsync://mirror.23m.com/archlinux";
        httpsUrl = "https://mirror.23m.com/archlinux";
      };
      sources.cachyos = {
        rsyncUrl = "rsync://202.61.194.133:8958/cachy";
      };
      sources.foxdenaur = {
        rsyncUrl = "rsync://mirror.foxden.network/foxdenaur";
      };
    };
    foxingress = {
      enable = true;
      host = "icefox-http";
      configText = builtins.readFile ./icefox-foxingress.yml;
    };
  };

  foxDen.dns.records = [
    {
      zone = "doridian.net";
      name = "mirror";
      type = "CNAME";
      ttl = 3600;
      value = "mirror-offsite.foxden.network.";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "cachyos";
      type = "CNAME";
      ttl = 3600;
      value = "mirror-offsite.foxden.network.";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "cachyos";
      type = "CNAME";
      ttl = 3600;
      value = "mirror-offsite.foxden.network.";
      horizon = "*";
    }
  ];

  foxDen.hosts.hosts = let
    mkHost = iface: {
      inherit (ifcfg) nameservers;
      interfaces.default = {
        inherit (iface) dns mac;
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
          vlan = 0;
        };
        routes = [
          { Destination = "10.0.0.0/8"; Gateway = "10.99.12.1"; }
          { Destination = "fd2c:f4cb:63be::/60"; Gateway = "fd2c:f4cb:63be::a63:c01"; }
        ];
      };
    };

    mkSniHost = (iface: lib.mkMerge [
      (mkHost ({ mac = null; } // iface))
      {
        interfaces.default.dns.auxAddresses = [ "95.216.116.180" ];
      }
    ]);
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
        "10.99.12.3/24"
        "fd2c:f4cb:63be::a63:c03/120"
      ];
      mac = "00:50:56:00:C1:7A";
    };
    icefox-http = mkHost {
      dns = {
        name = "icefox-http";
        zone = "foxden.network";
      };
      addresses = [
        "95.216.116.180/26"
        "2a01:4f9:2b:1a42::8/64"
        "10.99.12.2/24"
        "fd2c:f4cb:63be::a63:c02/120"
      ];
      mac = "00:50:56:00:81:B8";
    };
    syncthing = mkSniHost {
      dns = {
        name = "syncthing-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::6/64"
        "10.99.12.6/24"
        "fd2c:f4cb:63be::a63:c06/120"
      ];
    };
    restic = mkSniHost {
      dns = {
        name = "restic-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::7/64"
        "10.99.12.7/24"
        "fd2c:f4cb:63be::a63:c07/120"
      ];
    };
    nas = mkSniHost {
      dns = {
        name = "nas-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::5/64"
        "10.99.12.5/24"
        "fd2c:f4cb:63be::a63:c05/120"
      ];
    };
    xmpp = mkSniHost {
      dns = {
        name = "xmpp";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::4/64"
        "10.99.12.4/24"
        "fd2c:f4cb:63be::a63:c04/120"
      ];
    };
    jellyfin = mkSniHost {
      dns = {
        name = "jellyfin-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::9/64"
        "10.99.12.9/24"
        "fd2c:f4cb:63be::a63:c09/120"
      ];
    };
    kiwix = mkSniHost {
      dns = {
        name = "kiwix-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::a/64"
        "10.99.12.10/24"
        "fd2c:f4cb:63be::a63:c0a/120"
      ];
    };
  };

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = ["" "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin root --noclear --keep-baud %I 115200,38400,9600 $TERM"];
  };
}
