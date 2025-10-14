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
      "2a01:4f9:2b:1a42::0:1/112"
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

  users.users.kilian = {
    isNormalUser = true;
    autoSubUidGidRange = false;
    group = "kilian";
    uid = 1009;
    home = "/mnt/ztank/users/kilian";
    shell = "/run/current-system/sw/bin/fish";
  };
  users.groups.kilian = {
    gid = 1009;
  };

  virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
      { Destination = "::/0"; Gateway = "fe80::1"; }
    ];
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;

      DHCP = "no";
      IPv6AcceptRA = true;
    };
  };

  networking.nftables.tables = {
    nat = {
      content = ''
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ip saddr 10.99.12.0/24 oifname br-default snat to 95.216.116.140
        }
      '';
      family = "ip";
    };
  };

  networking.nftables.tables = {
    filter = {
      content = ''
        chain forward {
          type filter hook forward priority 0; policy accept;
          oifname ${phyIface} ether saddr & ff:ff:00:00:00:00 == e6:21:00:00:00:00 drop
        }
      '';
      family = "bridge";
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = "1";
    "net.ipv6.conf.all.forwarding" = "1";
    "net.ipv6.conf.default.forwarding" = "1";
  };

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

  systemd.network.netdevs.br-routed = {
    netdevConfig = {
      Name = "br-routed";
      Kind = "bridge";
      MACAddress = "e6:21:ff:00:00:01";
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

  systemd.network.networks."30-br-routed" = {
    name = "br-routed";
    address = [
      "2a01:4f9:2b:1a42::1:1/112"
    ];

    networkConfig = {
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
        listenPort = 13232;
        peers = [
          {
            allowedIPs = [ "10.99.1.1/32" "fd2c:f4cb:63be::a63:101/128" "10.0.0.0/8" "fd2c:f4cb:63be::/60" ];
            endpoint = "router.foxden.network:13232";
            persistentKeepalive = 25;
            publicKey = "nCTAIMDv50QhwjCw72FwP2u2pKGMcqxJ09DQ9wJdxH0=";
          }
          {
            allowedIPs = [ "10.99.10.1/32" "fd2c:f4cb:63be::a63:a01/128" ];
            endpoint = "redfox.doridian.net:13232";
            persistentKeepalive = 25;
            publicKey = "s1COjkpfpzfQ05ZLNLGQrlEhomlzwHv+APvUABzbSh8=";
          }
          {
            allowedIPs = [ "10.99.1.2/32" "fd2c:f4cb:63be::a63:102/128" ];
            endpoint = "router-backup.foxden.network:13232";
            persistentKeepalive = 25;
            publicKey = "8zUl7b1frvuzcBrIA5lNsegzzyAOniaZ4tczSdoqcWM=";
          }
        ];
      };
    };

    backupmgr.enable = true;
    deluge = {
      enable = true;
      host = "deluge";
      enableHttp = false;
      downloadsDir = "/mnt/ztank/local/torrent";
    };
    gitbackup = {
      enable = true;
      host = "";
    };
    syncthing = {
      enable = true;
      host = "syncthing";
      tls = true;
      syncthingHost = "syncthing.doridian.net";
      webdavHost = "webdav.syncthing.doridian.net";
    };
    kiwix = {
      enable = true;
      host = "kiwix";
      dataDir = "/mnt/zhdd/kiwix";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "kiwix-icefox";
        bypassInternal = true;
      };
    };
    nasweb = {
      host = "nas";
      enable = true;
      root = "/mnt/zhdd/nas";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "nas-icefox";
        bypassInternal = true;
      };
    };
    jellyfin = {
      host = "jellyfin";
      enable = true;
      mediaDir = "/mnt/zhdd/nas";
      tls = true;
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
    xmpp = {
      enable = true;
      host = "xmpp";
      tls = true;
      auxHosts = [ "xmpp.foxden.network" "upload.xmpp.foxden.network" ];
    };
    restic-server = {
      enable = true;
      host = "restic";
      dataDir = "/mnt/ztank/restic";
      tls = true;
    };
  };

  foxDen.dns.records = [
    {
      zone = "doridian.net";
      name = "cachyos";
      type = "CNAME";
      ttl = 3600;
      value = "mirror.doridian.net.";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "archlinux";
      type = "CNAME";
      ttl = 3600;
      value = "mirror.doridian.net.";
      horizon = "*";
    }
    {
      zone = "foxden.network";
      name = "xmpp";
      type = "CNAME";
      ttl = 3600;
      value = "foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxden.network";
      name = "www";
      type = "CNAME";
      ttl = 3600;
      value = "foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxden.network";
      name = "upload.xmpp";
      type = "CNAME";
      ttl = 3600;
      value = "foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxden.network";
      name = "webdav.syncthing";
      type = "CNAME";
      ttl = 3600;
      value = "syncthing.foxden.network.";
      horizon = "*";
    }
  ];

  foxDen.hosts.hosts = let
    mkIntHost = iface: {
      inherit (ifcfg) nameservers;
      interfaces.default = {
        inherit (iface) dns mac;
        addresses = lib.filter (ip: !(foxDenLib.util.isPrivateIP ip)) iface.addresses;
        driver = lib.mkDefault "hetzner";
        driverOpts = lib.mkDefault {
          network = "30-${ifcfg.interface}";
          bridge = ifcfg.interface;
        };
        routes = [ ];
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

    mkHost = (iface: lib.mkMerge [
      (mkIntHost iface)
      {
        interfaces.default.routes = [
          { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
          { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::0:1"; }
        ];
      }
    ]);

    mkV6Host = (iface: lib.mkMerge [
      (mkIntHost ({ mac = null; } // iface))
      {
        interfaces.default = {
          dns.auxAddresses = [ "95.216.116.180" ];
          routes = [
            { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::1:1"; }
          ];
          driver = "bridge";
          driverOpts = {
            bridge = "br-routed";
            vlan = 0;
          };
        };
        interfaces.s2s.routes = [
          { Destination = "0.0.0.0/0"; Gateway = "10.99.12.1"; }
        ];
      }
    ]);

    # Due to Hetzner routing, we have two IPv6 subnets
    # - 2a01:4f9:2b:1a42::0:/112 for hosts which have public IPv4
    # - 2a01:4f9:2b:1a42::1:/112 for hosts without public IPv4 (routed out via 95.216.116.140)
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
    icefox-http = mkHost {
      dns = {
        name = "icefox-http";
        zone = "foxden.network";
      };
      addresses = [
        "95.216.116.180/26"
        "2a01:4f9:2b:1a42::0:2/112"
        "10.99.12.2/24"
        "fd2c:f4cb:63be::a63:c02/120"
      ];
      mac = "00:50:56:00:81:B8";
    };
    mirror = mkHost {
      dns = {
        name = "mirror";
        zone = "doridian.net";
      };
      addresses = [
        "95.216.116.139/26"
        "2a01:4f9:2b:1a42::0:3/112"
        "10.99.12.3/24"
        "fd2c:f4cb:63be::a63:c03/120"
      ];
      mac = "00:50:56:00:C1:7A";
    };
    xmpp = mkHost {
      dns = {
        name = "@";
        zone = "foxden.network";
      };
      addresses = [
        "95.216.116.173/26"
        "2a01:4f9:2b:1a42::0:4/112"
        "10.99.12.4/24"
        "fd2c:f4cb:63be::a63:c04/120"
      ];
      mac = "00:50:56:00:D3:62";
    };
    nas = mkV6Host {
      dns = {
        name = "nas-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:5/112"
        "10.99.12.5/24"
        "fd2c:f4cb:63be::a63:c05/120"
      ];
    };
    syncthing = mkV6Host {
      dns = {
        name = "syncthing";
        zone = "doridian.net";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:6/112"
        "10.99.12.6/24"
        "fd2c:f4cb:63be::a63:c06/120"
      ];
    };
    restic = mkV6Host {
      dns = {
        name = "restic";
        zone = "doridian.net";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:7/112"
        "10.99.12.7/24"
        "fd2c:f4cb:63be::a63:c07/120"
      ];
    };
    jellyfin = mkV6Host {
      dns = {
        name = "jellyfin-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:9/112"
        "10.99.12.9/24"
        "fd2c:f4cb:63be::a63:c09/120"
      ];
    };
    kiwix = mkV6Host {
      dns = {
        name = "kiwix-offsite";
        zone = "foxden.network";
      };
      addresses = [
        "2a01:4f9:2b:1a42::1:a/112"
        "10.99.12.10/24"
        "fd2c:f4cb:63be::a63:c0a/120"
      ];
    };
    deluge = let
      host = mkIntHost {
        dns = {
          name = "deluge-offsite";
          zone = "foxden.network";
        };
        addresses = [
          "10.99.12.11/24"
          "fd2c:f4cb:63be::a63:c0b/120"
        ];
      };
    in {
      nameservers = [ "10.64.0.1" ];
      interfaces.s2s = host.interfaces.s2s;
    };
  };
}
