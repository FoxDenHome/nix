{  modulesPath, config, ... }:
let
  bridgeDev = config.foxDen.hostDriverOpts.bridge;
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

  boot.lanzaboote.enable = true;

  networking.bridges.${bridgeDev} = {
    interfaces = [ "enp1s0" ];
  };

  networking.interfaces.${bridgeDev}.ipv4 = {
    addresses = [{
      address = "192.168.122.200";
      prefixLength = 24;
    }];
    routes = [{
      address = "0.0.0.0";
      prefixLength = 0;
      via = "192.168.122.1";
    }];
  };

  foxDen.hosts.jellyfin = {
    name = "jellyfin";
    internal = {
      ipv4 = "192.168.122.201";
    };
  };
}
