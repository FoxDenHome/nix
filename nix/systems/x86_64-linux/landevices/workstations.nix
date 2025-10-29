{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    capefox = mkIntf {
      dns = {
        name = "capefox.foxden.network";
      };
      mac = "00:30:93:12:12:38";
      addresses = [
        "10.2.10.3/16"
      ];
    };
    capefox-wired = mkIntf {
      dns = {
        name = "capefox-wired.foxden.network";
      };
      mac = "00:30:93:12:12:39"; # TODO: Update MAC
      addresses = [
        "10.2.10.4/16"
      ];
    };
    crossfox = mkIntf {
      dns = {
        name = "crossfox.foxden.network";
      };
      mac = "B8:27:EB:ED:0F:4B";
      addresses = [
        "10.5.10.3/16"
      ];
    };
    fennec = mkIntf {
      dns = {
        name = "fennec.foxden.network";
      };
      mac = "7C:FE:90:31:7B:0E";
      addresses = [
        "10.2.10.1/16"
      ];
    };
    wizzy-desktop = mkIntf {
      dns = {
        name = "wizzy-desktop.foxden.network";
      };
      mac = "7C:FE:90:39:20:9A";
      addresses = [
        "10.2.10.2/16"
      ];
    };
  };
}
