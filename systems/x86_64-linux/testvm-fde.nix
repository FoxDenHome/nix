{  modulesPath, config, ... }:
let
  bridgeDev = config.foxDen.hosts.driverOpts.bridge;

  ipv4 = {
    host = "192.168.122.200";
    gateway = "192.168.122.1";
    prefixLength = 24;
  };
  ipv6 = {
    host = "fd00:dead:beef:122::200";
    gateway = "fd00:dead:beef:122::1";
    prefixLength = 64;
  };
in
{
  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices.nixroot.device = "/dev/vda2";

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
    { device = "/dev/vda1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  boot.lanzaboote.enable = true;

  networking.bridges.${bridgeDev} = {
    interfaces = [ "enp1s0" ];
  };

  networking.interfaces.${bridgeDev}.ipv4 = {
    addresses = [{
      address = ipv4.host;
      prefixLength = ipv4.prefixLength;
    }];
    routes = [{
      address = "0.0.0.0";
      prefixLength = 0;
      via = ipv4.gateway;
    }];
  };

  foxDen.hosts.routes = [
    {
      gateway = ipv4.gateway;
    }
  ];

  foxDen.hosts.driver = "bridge";

  foxDen.hosts.subnet = {
    ipv4 = ipv4.prefixLength;
    ipv6 = ipv6.prefixLength;
  };

  foxDen.hosts.hosts.system = {
    name = config.networking.hostName;
    root = "local.foxden.network";
    internal = {
      ipv4 = ipv4.host;
    };
  };

  foxDen.hosts.hosts.jellyfin = {
    name = "jellyfin";
    root = "local.foxden.network";
    internal = {
      ipv4 = "192.168.122.201";
    };
  };
}
