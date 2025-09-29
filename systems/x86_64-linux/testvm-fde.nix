{ modulesPath, pkgs, config, ... }:
let
  ifcfg = {
    addresses = [
      "192.168.122.200/24"
      "fd00:dead:beef:122::200/64"
    ];
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "192.168.122.1"; }
      { Destination = "::/0"; Gateway = "fd00:dead:beef:122::1"; }
    ];
    nameservers = [ "8.8.8.8" ];
    interface = "br-default";
  };

  rootInterface = "enp1s0";
in
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = true;
  foxDen.boot.secure = true;

  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices.nixroot.device = "/dev/vda2";

  # boot.swraid = {
  #   enable = true;
  #   mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=da97b4e7:f1803d7d:f9de9388:32aa60ad";
  # };

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/nixroot";
      fsType = "xfs";
    };

  # fileSystems."/aux" =
  #   { device = "/dev/md0";
  #     fsType = "xfs";
  #   };

  fileSystems."/boot" =
    { device = "/dev/vda1";
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

  foxDen.services.fadumper.enable = false;
  foxDen.services.fadumper.host = "fadumper";
  foxDen.services.e621dumper.enable = true;
  foxDen.services.e621dumper.host = "fadumper";

  foxDen.services.jellyfin = {
    enable = true;
    tls = false;
    host = "jellyfin";
  };
  foxDen.services.samba = {
    enable = true;
    host = "samba";
  };
  foxDen.services.nasweb = {
    enable = config.foxDen.sops.available;
    host = "samba";
    root = "/nix";
    oAuth = {
      enable = true;
      clientId = "nas-bengalfox";
      clientSecret = "something funny";
    };
  };
  foxDen.services.deluge = {
    enable = config.foxDen.sops.available;
    host = "deluge";
  };

  foxDen.services.wireguard."wg-deluge" = {
    host = "deluge";
    interface = {
      ips = [ "10.1.2.3/32" ];

      peers = [
        {
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "10.99.99.99:51820";
          persistentKeepalive = 25;
          publicKey = "BJCvDOX+Mrf1oNtvA84RZB2i1gZ6YA01GpP2BCQDdiY=";
        }
      ];
    };
  };
  
  foxDen.hosts.hosts = {
    jellyfin = {
      nameservers = ifcfg.nameservers;
      interfaces.ext = {
        driver = "bridge";
        driverOpts.bridge = "br-default";
        dns = {
          name = "jellyfin";
          zone = "local.foxden.network";
        };
        addresses = [
          "192.168.122.201/24"
          "fd00:dead:beef:122::201/64"
        ];
        routes = ifcfg.routes;
      };
    };
    samba = {
      nameservers = ifcfg.nameservers;
      interfaces.ext = {
        driver = "bridge";
        driverOpts.bridge = "br-default";
        dns = {
          name = "samba";
          zone = "local.foxden.network";
        };
        addresses = [
          "192.168.122.202/24"
          "fd00:dead:beef:122::202/64"
        ];
        routes = ifcfg.routes;
      };
    };
    deluge = {
      nameservers = ifcfg.nameservers;
      interfaces.ext = {
        driver = "bridge";
        driverOpts.bridge = "br-default";
        dns = {
          name = "deluge";
          zone = "local.foxden.network";
        };
        addresses = [
          "192.168.122.203/24"
          "fd00:dead:beef:122::203/64"
        ];
        routes = [
          {
            Destination = "10.0.0.0/8";
            Gateway = "192.168.122.1";
          }
          {
            Destination = "192.168.0.0/16";
            Gateway = "192.168.122.1";
          }
        ];
      };
    };
    fadumper = {
      nameservers = ifcfg.nameservers;
      interfaces.ext = {
        driver = "bridge";
        driverOpts.bridge = "br-default";
        dns = {
          name = "fadumper";
          zone = "local.foxden.network";
        };
        addresses = [
          "192.168.122.203/24"
          "fd00:dead:beef:122::203/64"
        ];
        routes = ifcfg.routes;
      };
    };
  };

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = ["" "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin root --noclear --keep-baud %I 115200,38400,9600 $TERM"];
  };

  foxDen.services.trustedProxies = [];
}
