{ lib, pkgs, modulesPath, ... }:
{
    boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" =
      { device = "/dev/vda2";
        fsType = "xfs";
      };

    fileSystems."/boot" =
      { device = "/dev/vda1";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
      };

  system = "x86_64-linux";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
