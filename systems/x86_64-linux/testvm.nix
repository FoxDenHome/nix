{  modulesPath, config, ... }:
let
  util = import ../../modules/util.nix { };

  bridgeDev = config.foxDen.hosts.driverOpts.bridge;
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
in
{
  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };

  fileSystems."/nix" =
    { device = "/dev/vda2";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/vda1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  networking.bridges.${bridgeDev} = {
    interfaces = [ "enp1s0" ];
  };

  networking.interfaces.${bridgeDev} = util.mkNwInterfaceConfig ifcfg;
  foxDen.hosts.routes = util.mkRoutes ifcfg;
  foxDen.hosts.subnet = util.mkSubnet ifcfg;

  foxDen.hosts.hosts.system = {
    name = config.networking.hostName;
    root = "local.foxden.network";
    manageNetwork = false;
    internal = {
      ipv4 = ifcfg.ipv4.address;
      ipv6 = ifcfg.ipv6.address;
    };
  };

  foxDen.hosts.driver = "bridge";

  foxDen.hosts.hosts.jellyfin = {
    name = "jellyfin";
    root = "local.foxden.network";
    internal = {
      ipv4 = "192.168.122.201";
    };
  };
}
