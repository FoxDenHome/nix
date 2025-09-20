{ nixpkgs, modulesPath, config, ... }:
let
  sysutil = import ../../modules/sysutil.nix { inherit config; inherit nixpkgs; };

  ifcfg.ipv4 = {
    address = "192.168.122.200";
    gateway = "192.168.122.1";
    prefixLength = 24;
  };
  ifcfg.ipv6 = {
    address = "fd00:dead:beef:122::200";
    gateway = "fd00:dead:beef:122::1";
    prefixLength = 64;
  };
  ifcfg.default = "enp1s0";
in
{
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

  systemd.network.networks."40-${ifcfg.default}" = sysutil.mkNetworkConfig ifcfg.default ifcfg;
  foxDen.hosts.routes = sysutil.mkRoutes ifcfg;
  foxDen.hosts.subnet = sysutil.mkSubnet ifcfg;
  foxDen.hosts.driver = "routed";

  foxDen.sops.available = true;
  foxDen.boot.secure = true;

  foxDen.hosts.hosts = {
    system = {
      name = config.networking.hostName;
      root = "local.foxden.network";
      manageNetwork = false;
      internal = {
        ipv4 = ifcfg.ipv4.address;
        ipv6 = ifcfg.ipv6.address;
      };
    };

    jellyfin = {
      name = "jellyfin";
      root = "local.foxden.network";
      internal = {
        ipv4 = "192.168.122.201";
        ipv6 = "fd00:dead:beef:122::201";
      };
    };
  };
}
