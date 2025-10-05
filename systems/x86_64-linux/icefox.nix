{ config, ... }:
let
  nameservers = [
    "213.133.98.98"
    "213.133.98.99"
    "213.133.98.100"
  ];
  interface = "enp7s0";
  interfaceAddresses = [
    "95.216.116.140/26"
    "2a01:4f9:2b:1a42::2/64"
  ];
  s2sAddresses = [
    "10.99.10.2/16"
    "fd2c:f4cb:63be::a63:a02/112"
  ];
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

  environment.etc."foxden/zfs-ztank.key" = config.lib.foxDen.sops.mkIfAvailable {
    source = config.sops.secrets."zfs-ztank.key".path;
    mode = "0400";
    user = "root";
    group = "root";
  };

  systemd.network.networks."30-${interface}" = {
    name = interface;
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "95.216.116.129"; }
    ];
    address = interfaceAddresses;
    dns = nameservers;

    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = true;
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
    ];

    backupmgr.enable = true;
  };

  foxDen.hosts.hosts = let
    driver = "routed";
    driverOpts = {
      network = interface;
    };
    routes = [
      { Destination = "95.216.116.140"; }
      { Destination = "2a01:4f9:2b:1a42::2"; }
      { Destination = "0.0.0.0/0"; Gateway = "95.216.116.140"; }
      { Destination = "::/0"; Gateway = "2a01:4f9:2b:1a42::2"; }
    ];
  in
  {
    icefox = {
      inherit nameservers;
      interfaces.default = {
        dns = {
          name = "icefox";
          zone = "foxden.network";
        };
        addresses = interfaceAddresses ++ s2sAddresses;
      };
    };
  };
}
