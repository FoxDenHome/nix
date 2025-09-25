{ modulesPath, config, ... }:
let
  ifcfg = config.foxDen.hosts.ifcfg;
  rootInterface = "enp1s0";
in
{
  system.stateVersion = "25.05";

  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  foxDen.hosts.ifcfg = {
    addresses = [
      "192.168.122.200/24"
      "fd00:dead:beef:122::200/64"
    ];
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "192.168.122.1"; }
      { Destination = "::/0"; Gateway = "fd00:dead:beef:122::1"; }
    ];
    dns = [ "8.8.8.8" ];
    interface = "br-default";
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

  foxDen.hosts.driver = "bridge";

  systemd.network.networks."${ifcfg.network}" =
    {
      # bridgeVLANs = [{
      #   PVID = 2;
      #   EgressUntagged = 2;
      #   VLAN = "1-10";
      # }];
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
}
