{ lib, pkgs, modulesPath, ... }:
{
    imports =
      [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

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
}
