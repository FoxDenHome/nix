{ modulesPath, pkgs, lib, config, ... }:
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
      "10.2.10.9/16"
      "fd2c:f4cb:63be:2::a09/64"
    ];
    routes = mkRoutes 2;
    nameservers = mkNameservers 2;
    interface = "br-default";
  };
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = true;
  foxDen.boot.secure = true;

  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "nvme" "mpt3sas" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  foxDen.nvidia.enable = true;

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md0 metadata=1.2 UUID=a84487b7:a5d11a87:32de3997:dacc0654
      ARRAY /dev/md1 metadata=1.2 UUID=115c644c:fcb4a527:5d784e0c:9c379b03
    '';
  };

  boot.initrd.luks.devices = {
      nixroot = {
        device = "/dev/md0";
        allowDiscards = true;
      };
      zssd = {
        device = "/dev/md1";
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

  fileSystems."/mnt/zssd" = {
    device = "/dev/mapper/zssd";
    fsType = "xfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd" = {
    device = "zhdd/ROOT";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/docker" = {
    device = "zhdd/ROOT/docker";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/e621" = {
    device = "zhdd/ROOT/e621";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/furaffinity" = {
    device = "zhdd/ROOT/furaffinity";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/kiwix" = {
    device = "zhdd/ROOT/kiwix";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/mirror" = {
    device = "zhdd/ROOT/mirror";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nas" = {
    device = "zhdd/ROOT/nas";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nashome" = {
    device = "zhdd/ROOT/nashome";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/restic" = {
    device = "zhdd/ROOT/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nas/torrent" = {
    device = "/mnt/zssd/nas/torrent";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/mnt/zhdd/nas/usenet" = {
    device = "/mnt/zssd/nas/usenet";
    options = [ "bind" "nofail" ];
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

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = ifcfg.routes;
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };

    bridgeVLANs = [{
      PVID = 2;
      EgressUntagged = 2;
      VLAN = "1-10";
    }];
  };

  systemd.network.networks."40-${ifcfg.interface}-root" = {
    name = "ens1f0np0";
    bridge = [ifcfg.interface];

    bridgeVLANs = [{
      PVID = 2;
      EgressUntagged = 2;
      VLAN = "1-10";
    }];
  };

  services.deluge.config.outgoing_interface = "wg-deluge";

  sops.secrets."zfs-zhdd.key" = config.lib.foxDen.sops.mkIfAvailable {
    format = "binary";
    sopsFile = ../../secrets/zfs-zhdd.key;
  };

  users.users.homeassistant = {
    description = "Home Assistant backup user";
    group = "homeassistant";
    isNormalUser = true;
    autoSubUidGidRange = false;
    uid = 1005;
    shell = "${pkgs.util-linux}/bin/nologin";
  };
  users.groups.homeassistant = {
    gid = 1005;
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

    apcupsd.enable = true;
    aurbuild = {
      enable = true;
      host = "mirror";
      packages = lib.strings.splitString "\n" (builtins.readFile ../../files/aurbuild-packages.txt);
      makepkgConf = builtins.readFile ../../files/aurbuild-makepkg.conf;
    };
    backupmgr.enable = true;
    deluge = {
      enable = true;
      host = "deluge";
      enableCaddy = false;
      downloadsDir = "/mnt/zssd/nas/torrent";
    };
    e621dumper = {
      enable = true;
      dataDir = "/mnt/zhdd/e621";
      host = "e621dumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "e621dumper";
        bypassInternal = true;
      };
    };
    fadumper = {
      enable = true;
      dataDir = "/mnt/zhdd/furaffinity";
      host = "fadumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "fadumper";
        bypassInternal = true;
      };
    };
    gitbackup = {
      enable = true;
      host = "";
    };
    jellyfin = {
      enable = true;
      host = "jellyfin";
      mediaDir = "/mnt/zhdd/nas";
      tls = true;
    };
    kiwix = {
      enable = true;
      host = "kiwix";
      dataDir = "/mnt/zhdd/kiwix";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "kiwix-bengalfox";
        bypassInternal = true;
      };
    };
    mirror = {
      enable = true;
      host = "mirror";
      tls = true;
      dataDir = "/mnt/zhdd/mirror";
      archMirrorId = "archlinux.doridian.net";
      sources.archlinux = {
        rsyncUrl = "rsync://mirror.doridian.net/archlinux/";
        forceSync = true;
      };
      sources.cachyos = {
        rsyncUrl = "rsync://mirror.doridian.net/cachyos/";
        forceSync = true;
      };
    };
    nasweb = {
      host = "nas";
      enable = true;
      root = "/mnt/zhdd/nas";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "nas-bengalfox";
        bypassInternal = true;
      };
    };
    nzbget = {
      enable = true;
      host = "nzbget";
      enableCaddy = false;
      downloadsDir = "/mnt/zssd/nas/usenet";
    };
    restic-server = {
      enable = true;
      host = "restic";
      dataDir = "/mnt/zhdd/restic";
      tls = true;
    };
    samba = {
      enable = true;
      host = "nas";
      sharePaths = [ "/mnt/zhdd/nas" "/mnt/zhdd/nashome" ];
    };
    superfan.enable = true;
  };

  services.samba.settings = {
    homes = {
      "comment" = "Home Directories";
      "browseable" = "no";
      "guest ok" = "no";
      "writable" = "yes";
      "create mask" = "0600";
      "directory mask" = "0700";
      "path" = "/mnt/zhdd/nashome/%u";
      "follow symlinks" = "no";
      "wide links" = "no";
    };
    share = {
      "comment" = "NAS share";
      "browseable" = "yes";
      "guest ok" = "yes";
      "read only" = "yes";
      "write list" = "wizzy doridian";
      "printable" = "no";
      "create mask" = "0664";
      "force create mode" = "0664";
      "force group" = "share";
      "directory mask" = "2775";
      "force directory mode" = "2775";
      "path" = "/mnt/zhdd/nas";
      "follow symlinks" = "no";
      "wide links" = "no";
      "veto files" = "/.*/";
      "delete veto files" = "yes";
    };
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
    bengalfox = {
      interfaces.default = {
        driver = "null";
        dns = {
          name = "bengalfox";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = ifcfg.addresses;
      };
    };
    deluge = (mkVlanHost 2 {
      dns = {
        name = "deluge";
        cnames = ["dldr"];
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.8/16"
        "fd2c:f4cb:63be:2::b08/64"
      ];
      routes = [
        { Destination = "10.0.0.0/8"; Gateway = "10.2.0.1"; }
        { Destination = "fd2c:f4cb:63be::/48"; Gateway = "fd2c:f4cb:63be:2::1"; }
      ];
    }) // {
      nameservers = [ "10.64.0.1" ];
    };
    e621dumper = mkVlanHost 3 {
      dns = {
        name = "e621";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.12/16"
        "fd2c:f4cb:63be:3::a0c/64"
      ];
    };
    fadumper = mkVlanHost 3 {
      dns = {
        name = "furaffinity";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.13/16"
        "fd2c:f4cb:63be:3::a0d/64"
      ];
    };
    jellyfin = mkVlanHost 2 {
      dns = {
        name = "jellyfin";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.3/16"
        "fd2c:f4cb:63be:2::b03/64"
      ];
    };
    kiwix = mkVlanHost 2 {
      dns = {
        name = "kiwix";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.6/16"
        "fd2c:f4cb:63be:2::b06/64"
      ];
    };
    mirror = mkVlanHost 3 {
      dns = {
        name = "mirror";
        cnames = ["archlinux" "cachyos"];
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.11/16"
        "fd2c:f4cb:63be:3::a0b/64"
      ];
    };
    nas = mkVlanHost 2 {
      dns = {
        name = "nas";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.1/16"
        "fd2c:f4cb:63be:2::b01/64"
      ];
    };
    nzbget = mkVlanHost 2 {
      dns = {
        name = "nzbget";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.9/16"
        "fd2c:f4cb:63be:2::b09/64"
      ];
    };
    restic = mkVlanHost 2 {
      dns = {
        name = "restic";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.12/16"
        "fd2c:f4cb:63be:2::b0c/64"
      ];
    };
  };
}
