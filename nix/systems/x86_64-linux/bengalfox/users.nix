{ ... }:
{
  users.users.homeassistant = {
    description = "Home Assistant backup user";
    group = "homeassistant";
    isNormalUser = true;
    autoSubUidGidRange = false;
    uid = 1005;
    shell = "/run/current-system/sw/bin/nologin";
  };
  users.groups.homeassistant = {
    gid = 1005;
  };
}
