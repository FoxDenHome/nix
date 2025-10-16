{ config, ... }:
{
  # These are set when you reinstall the system
  # Change them to "false" for first boot, before secrets exist
  # then, once stuff is done, set them to true
  foxDen.sops.available = true;
  foxDen.boot.secure = true;

  system.stateVersion = "25.05";

  services.timesyncd.servers = ["ntp1.hetzner.de" "ntp2.hetzner.com" "ntp3.hetzner.net"];

  boot.swraid = {
    enable = true;
    mdadmConf = "ARRAY /dev/md0 metadata=1.2 UUID=f8fef6b4:264144e8:1d611b0a:ba263ab2";
  };

  boot.initrd.luks.devices = {
    nixroot = {
      device = "/dev/md0";
      allowDiscards = true;
    };
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/nixroot";
    fsType = "xfs";
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "nofail" ];
  };

  fileSystems."/boot2" = {
    device = "/dev/nvme1n1p1";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "nofail" ];
  };

  fileSystems."/mnt/ztank" = {
    device = "ztank/ROOT";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local" = {
    device = "ztank/ROOT/local";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/backups" = {
    device = "ztank/ROOT/local/backups";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/backups/arcticfox" = {
    device = "ztank/ROOT/local/backups/arcticfox";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/mirror" = {
    device = "ztank/ROOT/local/mirror";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/restic" = {
    device = "ztank/ROOT/local/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/torrent" = {
    device = "ztank/ROOT/local/torrent";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/local/usenet" = {
    device = "ztank/ROOT/local/usenet";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/restic" = {
    device = "ztank/ROOT/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/users" = {
    device = "ztank/ROOT/users";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/ztank/users/kilian" = {
    device = "ztank/ROOT/users/kilian";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd" = {
    device = "ztank/ROOT/zhdd";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/restic" = {
    device = "ztank/ROOT/zhdd/restic";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/e621" = {
    device = "ztank/ROOT/zhdd/e621";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/furaffinity" = {
    device = "ztank/ROOT/zhdd/furaffinity";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/kiwix" = {
    device = "ztank/ROOT/zhdd/kiwix";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nas" = {
    device = "ztank/ROOT/zhdd/nas";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/zhdd/nashome" = {
    device = "ztank/ROOT/zhdd/nashome";
    fsType = "zfs";
    options = [ "nofail" ];
  };

  sops.secrets."zfs-ztank.key" = config.lib.foxDen.sops.mkIfAvailable {
    format = "binary";
    sopsFile = ../../../secrets/zfs-ztank.key;
  };

  users.users.kilian = {
    isNormalUser = true;
    autoSubUidGidRange = false;
    group = "kilian";
    uid = 1009;
    home = "/mnt/ztank/users/kilian";
    shell = "/run/current-system/sw/bin/fish";
  };
  users.groups.kilian = {
    gid = 1009;
  };

  foxDen.services = {
    watchdog.enable = true;
    backupmgr.enable = config.lib.foxDen.sops.mkIfAvailable true;
  };
}
