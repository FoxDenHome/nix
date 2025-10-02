{ config, ... }:
let
  ifcfg = {
    addresses = [
      "10.2.10.9/16"
      "fd2c:f4cb:63be:2::a09/64"
    ];
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "10.2.0.1"; }
      { Destination = "::/0"; Gateway = "fd2c:f4cb:63be:2::1"; }
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

  # TODO: ZFS stuff

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

  services.deluge.config.outgoing_interface = "wg-deluge";

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
        ips = [ "10.64.17.204/32" ];
        peers = [
          {
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            endpoint = "23.234.81.127:51820";
            persistentKeepalive = 25;
            publicKey = "G6+A375GVmuFCAtvwgx3SWCWhrMvdQ+cboXQ8zp2ang=";
          }
        ];
      };
    };

    aurbuild.enable = true;
    backupmgr.enable = true;
    deluge = {
      enable = true;
      host = "deluge";
      enableCaddy = false;
    };
    e621dumper = {
      enable = true;
      host = "e621dumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "e621dumper"; # TODO: Secrets
        bypassInternal = true;
      };
    };
    fadumper = {
      enable = true;
      host = "fadumper";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "fadumper"; # TODO: Secrets
        bypassInternal = true;
      };
    };
    gitbackup.enable = true; # TODO: Secrets
    jellyfin = {
      enable = true;
      host = "jellyfin";
      tls = true;
    };
    kiwix = {
      enable = true;
      host = "kiwix";
      tls = true;
      oAuth = {
        enable = true;
        clientId = "kiwix-bengalfox"; # TODO: Secrets
        bypassInternal = true;
      };
    };
    mirror = {
      enable = true;
      host = "mirror";
      tls = true;
    };
    nasweb = {
      host = "nas";
      enable = true;
      tls = true;
      oAuth = {
        enable = true;
        clientId = "nas-bengalfox"; # TODO: Secrets
        bypassInternal = true;
      };
    };
    restic-server = {
      enable = true;
      host = "restic"; # TODO: Mount the old volume in
      tls = true;
    };
    samba = {
      enable = true;
      host = "nas";
    };
  };

  foxDen.hosts.hosts = let
    driver = "bridge";
    mkDriverOpts = (vlan : {
      bridge = ifcfg.interface;
      vlan = vlan;
    });
    driverOpts = mkDriverOpts 2;
    nameservers = ifcfg.nameservers;
    mkNameservers = (vlan: [
      "10.${vlan}.0.53"
    ]);
    routes = ifcfg.routes;
  in {
    bengalfox = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "bengalfox";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = ifcfg.addresses;
        inherit routes;
      };
    };
    deluge = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "deluge";
          cnames = ["dldr"];
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.2.11.8/16"
          "fd2c:f4cb:63be:2::b08/64"
        ];
        routes = [
          { Destination = "10.0.0.0/8"; Gateway = "10.2.0.1"; }
          { Destination = "fd2c:f4cb:63be::/48"; Gateway = "fd2c:f4cb:63be:2::1/64"; }
        ];
        inherit driver driverOpts;
      };
    };
    e621dumper = {
      nameservers = mkNameservers 3;
      interfaces.default = {
        dns = {
          name = "e621";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.3.10.12/16"
          "fd2c:f4cb:63be:3::a0c/64"
        ];
        driverOpts = mkDriverOpts 3;
        inherit routes driver;
      };
    };
    fadumper = {
      nameservers = mkNameservers 3;
      interfaces.default = {
        dns = {
          name = "furaffinity";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.3.10.13/16"
          "fd2c:f4cb:63be:3::a0d/64"
        ];
        driverOpts = mkDriverOpts 3;
        inherit routes driver;
      };
    };
    jellyfin = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "jellyfin";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.2.11.3/16"
          "fd2c:f4cb:63be:2::b03/64"
        ];
        inherit routes driver driverOpts;
      };
    };
    kiwix = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "kiwix";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.2.11.6/16"
          "fd2c:f4cb:63be:2::b06/64"
        ];
        inherit routes driver driverOpts;
      };
    };
    mirror = {
      nameservers = mkNameservers 3;
      interfaces.default = {
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
        driverOpts = mkDriverOpts 3;
        inherit routes driver;
      };
    };
    nas = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "nas";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.2.11.1/16"
          "fd2c:f4cb:63be:2::b01/64"
        ];
        inherit routes driver driverOpts;
      };
    };
    restic = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "restic";
          zone = "foxden.network";
          dynDns = true;
        };
        addresses = [
          "10.2.11.12/16"
          "fd2c:f4cb:63be:2::b0c/64"
        ];
        inherit routes driver driverOpts;
      };
    };
  };
}
