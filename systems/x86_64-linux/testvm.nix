{ nixpkgs, lib, modulesPath, config, ... }:
let
  sysutil = import ../../modules/sysutil.nix { inherit config; inherit nixpkgs; };

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
  ifcfg.dns = [ "8.8.8.8" ];
  ifcfg.default = "enp1s0";
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

  systemd.network.netdevs."40-${bridgeDev}" = {
    netdevConfig = {
      Name = bridgeDev;
      Kind = "bridge";
    };

    bridgeConfig = {
      VLANFiltering = true;
    };
  };

  systemd.network.networks."40-${ifcfg.default}" = sysutil.mkNetworkConfig lib.mkMerge [
    {
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
    }
    ifcfg.default ifcfg];

  systemd.network.networks."40-${bridgeDev}-${ifcfg.default}" = {
      name = ifcfg.default;
      bridge = [bridgeDev];
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
  };

  foxDen.hosts.routes = sysutil.mkRoutes ifcfg;
  foxDen.hosts.subnet = sysutil.mkSubnet ifcfg;

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
