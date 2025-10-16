{ ... }:
{
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
}
