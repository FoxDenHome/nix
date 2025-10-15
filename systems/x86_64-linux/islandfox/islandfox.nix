{ modulesPath, config, ... }:
let
  mkNameservers = (vlan: [
    "10.${builtins.toString vlan}.0.53"
    "fd2c:f4cb:63be:${builtins.toString vlan}\::35"
  ]);
  mkRoutes = (vlan: [
    { Destination = "0.0.0.0/0"; Gateway = "10.${builtins.toString vlan}.0.1"; }
  ]);

  ifcfg = {
    addresses = [
      "10.2.10.11/16"
      "fd2c:f4cb:63be:2::a0b/64"
    ];
    routes = mkRoutes 2;
    nameservers = mkNameservers 2;
    interface = "br-default";
    mac = "04:7b:cb:44:c0:dd";
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
  hardware.cpu.amd.updateMicrocode = true;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics.enable = true;

  boot.swraid = {
    enable = true;
    mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=660f8703:f7ec5be9:b586b082:ce74a589";
  };

  boot.extraModprobeConfig = ''
    blacklist bluetooth
    blacklist btintel
    blacklist btrtl
    blacklist btmtk
    blacklist btbcm
    blacklist btusb

    alias pci:v00008086d00002723sv00008086sd00000080bc02sc80i00 vfio-pci
    options vfio-pci ids=8086:0080
  '';

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
    device = "/dev/sda1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "nofail" ];
  };

  systemd.network.networks."30-${ifcfg.interface}" = {
    name = ifcfg.interface;
    routes = ifcfg.routes;
    address = ifcfg.addresses;
    dns = ifcfg.nameservers;

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = true;
    };

    bridgeVLANs = [{
      PVID = 2;
      EgressUntagged = 2;
      VLAN = "2";
    }];
  };

  systemd.network.netdevs."${ifcfg.interface}" = {
    netdevConfig = {
      Name = ifcfg.interface;
      Kind = "bridge";
      MACAddress = ifcfg.mac;
    };

    bridgeConfig = {
      VLANFiltering = true;
    };
  };

  systemd.network.networks."40-${ifcfg.interface}-root" = {
    name = "enp1s0f1";
    bridge = [ifcfg.interface];

    bridgeVLANs = [{
      PVID = 2;
      EgressUntagged = 2;
      VLAN = "1-10";
    }];
  };

  virtualisation.libvirtd.allowedBridges = [ ifcfg.interface ];

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

    watchdog.enable = true;

    apcupsd.enable = true;
    backupmgr.enable = true;
    darksignsonline = {
      enable = true;
      domain = "darksignsonline.com";
      host = "darksignsonline";
    };
    gitbackup = {
      enable = true;
      host = "";
    };
    syncthing = {
      enable = true;
      host = "syncthing";
      tls = true;
      syncthingHost = "syncthing.foxden.network";
      webdavHost = "webdav.syncthing.foxden.network";
    };
    kanidm.server = {
      enable = true;
      tls = true;
      host = "auth";
    };
    oauth-jit-radius = {
      enable = true;
      host = "radius";
      tls = true;
      oAuth = {
        clientId = "radius";
      };
    };
    unifi = {
      enable = true;
      host = "unifi";
      enableHttp = true;
      tls = true;
    };
    scrypted = {
      enable = true;
      host = "scrypted";
    };
    foxcaves = {
      enable = true;
      host = "foxcaves";
    };
    doridian-website = {
      enable = true;
      host = "doridian-website";
      auxHosts = [ "doridian.net" ];
      tls = true;
    };
    minecraft = {
      enable = true;
      host = "minecraft";
    };
    forgejo = {
      enable = true;
      host = "git";
      tls = true;
    };
    grafana = {
      enable = true;
      host = "grafana";
      tls = true;
    };
    mktxp = {
      enable = true;
      host = "mktxp";
    };
    prometheus = {
      enable = true;
      host = "prometheus";
    };
    telegraf = {
      enable = true;
      host = "telegraf";
    };
    spaceage-api = {
      enable = true;
      host = "spaceage-api";
      auxHosts = [ "api.spaceage.mp" ];
      tls = true;
    };
    spaceage-website = {
      enable = true;
      host = "spaceage-website";
      auxHosts = [ "spaceage.mp" "www.spaceage.mp" ];
      tls = true;
    };
    spaceage-tts = {
      enable = true;
      host = "spaceage-tts";
      auxHosts = [ "tts.spaceage.mp" ];
      tls = true;
    };
    spaceage-gmod = {
      enable = true;
      host = "spaceage-gmod";
    };
  };

  foxDen.hosts.index = 2;

  foxDen.dns.records = [
    {
      zone = "doridian.net";
      name = "@";
      type = "ALIAS";
      ttl = 3600;
      value = "website.foxden.network.";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "www";
      type = "ALIAS";
      ttl = 3600;
      value = "website.foxden.network.";
      horizon = "*";
    }
    {
      zone = "darksignsonline.com";
      name = "@";
      type = "ALIAS";
      ttl = 3600;
      value = "darksignsonline.foxden.network.";
      horizon = "*";
    }
    {
      zone = "darksignsonline.com";
      name = "www";
      type = "ALIAS";
      ttl = 3600;
      value = "darksignsonline.foxden.network.";
      horizon = "*";
    }
    {
      zone = "f0x.es";
      name = "@";
      type = "ALIAS";
      ttl = 3600;
      value = "foxcaves.foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxcav.es";
      name = "@";
      type = "ALIAS";
      ttl = 3600;
      value = "foxcaves.foxden.network.";
      horizon = "*";
    }
    {
      zone = "f0x.es";
      name = "www";
      type = "ALIAS";
      ttl = 3600;
      value = "foxcaves.foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxcav.es";
      name = "www";
      type = "ALIAS";
      ttl = 3600;
      value = "foxcaves.foxden.network.";
      horizon = "*";
    }
    {
      zone = "spaceage.mp";
      name = "@";
      type = "ALIAS";
      ttl = 3600;
      value = "spaceage-website.foxden.network.";
      horizon = "*";
    }
    {
      zone = "spaceage.mp";
      name = "www";
      type = "ALIAS";
      ttl = 3600;
      value = "spaceage-website.foxden.network.";
      horizon = "*";
    }
    {
      zone = "spaceage.mp";
      name = "tts";
      type = "ALIAS";
      ttl = 3600;
      value = "spaceage-tts.foxden.network.";
      horizon = "*";
    }
    {
      zone = "spaceage.mp";
      name = "api";
      type = "ALIAS";
      ttl = 3600;
      value = "spaceage-api.foxden.network.";
      horizon = "*";
    }
    {
      zone = "foxden.network";
      name = "mc";
      type = "CNAME";
      ttl = 3600;
      value = "minecraft.foxden.network.";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "mc";
      type = "CNAME";
      ttl = 3600;
      value = "minecraft.foxden.network.";
      horizon = "*";
    }
  ];

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
        driver = "null";
        dns = {
          name = "islandfox";
          zone = "foxden.network";
        };
        addresses = ifcfg.addresses;
      };
    };
    darksignsonline = mkVlanHost 3 {
      dns = {
        name = "darksignsonline";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.15/16"
        "fd2c:f4cb:63be:3::a0f/64"
      ];
    };
    foxcaves = mkVlanHost 3 {
      dns = {
        name = "foxcaves";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.1/16"
        "fd2c:f4cb:63be:3::a01/64"
      ];
    };
    syncthing = mkVlanHost 2 {
      dns = {
        name = "syncthing";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.2/16"
        "fd2c:f4cb:63be:2::b02/64"
      ];
    };
    grafana = mkVlanHost 2 {
      dns = {
        name = "grafana";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.2.11.5/16"
        "fd2c:f4cb:63be:2::b05/64"
      ];
    };
    prometheus = mkVlanHost 2 {
      dns = {
        name = "prometheus";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.20/16"
        "fd2c:f4cb:63be:2::b14/64"
      ];
    };
    telegraf = mkVlanHost 2 {
      dns = {
        name = "telegraf";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.21/16"
        "fd2c:f4cb:63be:2::b15/64"
      ];
    };
    mktxp = mkVlanHost 2 {
      dns = {
        name = "mktxp";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.22/16"
        "fd2c:f4cb:63be:2::b16/64"
      ];
    };
    auth = mkVlanHost 1 {
      dns = {
        name = "auth";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.1.14.1/16"
        "fd2c:f4cb:63be:1::e01/64"
      ];
    };
    radius = mkVlanHost 1 {
      dns = {
        name = "radius.auth";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.1.14.2/16"
        "fd2c:f4cb:63be:1::e02/64"
      ];
    };
    scrypted = mkVlanHost 2 {
      dns = {
        name = "scrypted";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.11.16/16"
        "fd2c:f4cb:63be:2::b10/64"
      ];
    };
    unifi = mkVlanHost 1 {
      dns = {
        name = "unifi";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.1.10.1/16"
        "fd2c:f4cb:63be:1::a01/64"
      ];
    };
    doridian-website = mkVlanHost 3 {
      dns = {
        name = "website";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.10/16"
        "fd2c:f4cb:63be:3::a0a/64"
      ];
    };
    minecraft = mkVlanHost 3 {
      dns = {
        name = "minecraft";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.8/16"
        "fd2c:f4cb:63be:3::a08/64"
      ];
    };
    git = mkVlanHost 3 {
      dns = {
        name = "git";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.2/16"
        "fd2c:f4cb:63be:3::a02/64"
      ];
    };
    spaceage-gmod = mkVlanHost 3 {
      dns = {
        name = "spaceage-gmod";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.4/16"
        "fd2c:f4cb:63be:3::a04/64"
      ];
    };
    spaceage-api = mkVlanHost 3 {
      dns = {
        name = "spaceage-api";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.5/16"
        "fd2c:f4cb:63be:3::a05/64"
      ];
    };
    spaceage-tts = mkVlanHost 3 {
      dns = {
        name = "spaceage-tts";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.6/16"
        "fd2c:f4cb:63be:3::a06/64"
      ];
    };
    spaceage-website = mkVlanHost 3 {
      dns = {
        name = "spaceage-website";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.3.10.9/16"
        "fd2c:f4cb:63be:3::a09/64"
      ];
    };
  };
}
