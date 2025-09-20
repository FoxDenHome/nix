{ modulesPath, config, ... }:
let
  ifcfg = config.foxDen.hosts.ifcfg;
  bridgeDev = config.foxDen.hosts.driverOpts.bridge;
in
{
  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  foxDen.hosts.ifcfg = {
    ipv4 = {
      address = "192.168.122.200";
      gateway = "192.168.122.1";
      prefixLength = 24;
    };
    ipv6 = {
      address = "fd00:dead:beef:122::200";
      gateway = "fd00:dead:beef:122::1";
      prefixLength = 64;
    };
    dns = [ "8.8.8.8" ];
    interface = "enp1s0";
  };

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

  systemd.network.networks."${ifcfg.network}" =
    {
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
    };

  systemd.network.networks."40-${bridgeDev}-${ifcfg.interface}" = {
      name = ifcfg.interface;
      bridge = [bridgeDev];
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
  };

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
      };
    };
  };
}
