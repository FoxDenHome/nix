{ ... }:
{
  system.stateVersion = "25.05";

  # TODO: Most of this file

  foxDen.hosts.hosts.jellyfin = {
    name = "jellyfin";
    internal = {
      ipv4 = "192.168.1.11";
    };
    external = {
      ipv4 = "dyn";
    };
  };

  foxDen.hosts.hosts.icefox = {
    name = "icefox";
    manageNetwork = false;
    internal = {
      ipv4 = "192.168.1.99";
      records = [
        {
          type = "TXT";
          value = "hello";
        }
      ];
    };
    external = {
      ipv4 = "dyn";
    };
  };

  foxDen.hosts.hosts.dummy = {
    name = "dummy";
    internal = {
      ipv4 = "192.168.1.100";
    };
    external = {
      ipv4 = "dyn";
    };
  };
}
