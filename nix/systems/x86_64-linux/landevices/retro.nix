{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    wii = mkIntf {
      dns = {
        name = "wii";
        zone = "foxden.network";
      };
      mac = "00:27:09:8A:A7:49";
      addresses = [
        "100.96.41.101/24"
      ];
    };
    ps2 = mkIntf {
      dns = {
        name = "ps2";
        zone = "foxden.network";
      };
      mac = "00:27:09:FF:A7:49";
      addresses = [
        "100.96.41.102/24"
      ];
    };
    mister = mkIntf {
      dns = {
        name = "mister";
        zone = "foxden.network";
      };
      mac = "02:03:04:05:06:07";
      addresses = [
        "100.96.41.253/24"
      ];
    };
  };
}
