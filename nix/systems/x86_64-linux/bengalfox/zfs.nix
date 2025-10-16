{ config, lib, ... }:
let
  zhddMounts = [
    ""
    "e621"
    "furaffinity"
    "kiwix"
    "mirror"
    "nas"
    "nashome"
    "restic"
  ];
in
{
  fileSystems = lib.listToAttrs (map (mount: let
    suffix = if mount == "" then "" else "/${mount}";
  in
  {
    name = "/mnt/zhdd${suffix}";
    value = {
      device = "zhdd/ROOT${suffix}";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  }) zhddMounts);

  sops.secrets."zfs-zhdd.key" = config.lib.foxDen.sops.mkIfAvailable {
    format = "binary";
    sopsFile = ../../../secrets/zfs-zhdd.key;
  };
}
