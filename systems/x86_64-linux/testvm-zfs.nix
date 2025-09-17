{ ... }:
{
  fileSystems."/mnt/zhdd" =
    { device = "zhdd/ROOT";
      fsType = "zfs";
    };
}