{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    bengalfox-ipmi = mkIntf {
      dns = {
        name = "bengalfox-ipmi";
        zone = "foxden.network";
      };
      mac = "00:25:90:FF:CF:5B";
      addresses = [
        "10.1.12.1/16"
        "fd2c:f4cb:63be:1::0c01/64"
      ];
    };
    ups-rack = mkIntf {
      dns = {
        name = "ups-rack";
        zone = "foxden.network";
      };
      mac = "00:C0:B7:E8:B2:A0";
      addresses = [
        "10.1.11.2/16"
      ];
    };
    tape-library = mkIntf {
      dns = {
        name = "tape-library";
        zone = "foxden.network";
      };
      mac = "00:0E:11:14:70:8B";
      addresses = [
        "10.1.13.1/16"
      ];
    };
    pikvm-rack = mkIntf {
      dns = {
        name = "pikvm-rack";
        zone = "foxden.network";
      };
      mac = "D8:3A:DD:A3:82:A8";
      addresses = [
        "10.1.13.2/16"
        "fd2c:f4cb:63be:1::0d02/64"
      ];
    };
  };
}
