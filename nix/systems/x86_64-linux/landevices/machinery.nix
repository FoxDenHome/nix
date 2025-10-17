{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    bambu-x1 = mkIntf {
      dns = {
        name = "bambu-x1";
        zone = "foxden.network";
      };
      mac = "08:FB:EA:02:64:96";
      addresses = [
        "10.4.10.1/16"
      ];
    };
    carvera = mkIntf {
      dns = {
        name = "carvera";
        zone = "foxden.network";
      };
      mac = "EC:C7:00:1C:E3:2D";
      addresses = [
        "10.4.10.3/16"
      ];
    };
    carvera-controller = mkIntf {
      dns = {
        name = "carvera-controller";
        zone = "foxden.network";
      };
      mac = "6C:6E:07:1B:1D:24";
      addresses = [
        "10.4.10.2/16"
      ];
    };
    laser-controller = mkIntf {
      dns = {
        name = "laser-controller";
        zone = "foxden.network";
      };
      mac = "8C:16:45:46:05:22";
      addresses = [
        "10.4.10.5/16"
      ];
    };
  };
}
