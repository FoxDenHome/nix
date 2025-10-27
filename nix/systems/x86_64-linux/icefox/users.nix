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

  users.users.bengalfox = {
    isNormalUser = true;
    autoSubUidGidRange = false;
    group = "bengalfox";
    uid = 1003;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHFHMI5pnBacMCpf2TnOluiqOCCQVYs0hnH2ZpicIUV root@bengalfox"
    ];
  };
  users.groups.bengalfox = {
    gid = 1003;
  };
}
