{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    capefox = mkIntf {
      dns = {
        name = "capefox";
        zone = "foxden.network";
      };
      mac = "00:30:93:12:12:38";
      addresses = [
        "10.2.10.3/16"
        "fd2c:f4cb:63be:2::0a03/64"
      ];
    };
    fennec = mkIntf {
      dns = {
        name = "fennec";
        zone = "foxden.network";
      };
      mac = "7C:FE:90:31:7B:0E";
      addresses = [
        "10.2.10.1/16"
        "fd2c:f4cb:63be:2::0a01/64"
      ];
    };
    wizzy-desktop = mkIntf {
      dns = {
        name = "wizzy-desktop";
        zone = "foxden.network";
      };
      mac = "7C:FE:90:39:20:9A";
      addresses = [
        "10.2.10.2/16"
        "fd2c:f4cb:63be:2::0a02/64"
      ];
    };
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
    pdu-rack = mkIntf {
      dns = {
        name = "pdu-rack";
        zone = "foxden.network";
      };
      mac = "70:A7:41:F8:13:09";
      addresses = [
        "10.1.11.1/16"
      ];
    };
    switch-den = mkIntf {
      dns = {
        name = "switch-den";
        zone = "foxden.network";
      };
      mac = "24:5A:4C:A6:6B:9A";
      addresses = [
        "10.1.10.2/16"
      ];
    };
    switch-rack-agg = mkIntf {
      dns = {
        name = "switch-rack-agg";
        zone = "foxden.network";
      };
      mac = "24:5A:4C:56:41:C4";
      addresses = [
        "10.1.10.3/16"
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
    ap-backyard = mkIntf {
      dns = {
        name = "ap-backyard";
        zone = "foxden.network";
      };
      mac = "68:D7:9A:1F:57:E2";
      addresses = [
        "10.1.10.6/16"
      ];
    };
    ap-corridor-upper = mkIntf {
      dns = {
        name = "ap-corridor-upper";
        zone = "foxden.network";
      };
      mac = "60:22:32:1D:48:15";
      addresses = [
        "10.1.10.7/16"
      ];
    };
    switch-dori-office-agg = mkIntf {
      dns = {
        name = "switch-dori-office-agg";
        zone = "foxden.network";
      };
      mac = "AC:8B:A9:A6:E7:EE";
      addresses = [
        "10.1.10.10/16"
      ];
    };
    ups-dori-office = mkIntf {
      dns = {
        name = "ups-dori-office";
        zone = "foxden.network";
      };
      mac = "00:0C:15:04:39:93";
      addresses = [
        "10.1.11.3/16"
      ];
    };
    printer = mkIntf {
      dns = {
        name = "printer";
        zone = "foxden.network";
      };
      mac = "64:C6:D2:E5:91:45";
      addresses = [
        "10.2.12.3/16"
      ];
    };
    hue = mkIntf {
      dns = {
        name = "hue";
        zone = "foxden.network";
      };
      mac = "C4:29:96:B5:2B:8F";
      addresses = [
        "10.2.12.1/16"
      ];
    };
    camera-living-room = mkIntf {
      dns = {
        name = "camera-living-room";
        zone = "foxden.network";
      };
      mac = "68:D7:9A:CF:30:09";
      addresses = [
        "10.5.11.2/16"
      ];
    };
    amp-living-room = mkIntf {
      dns = {
        name = "amp-living-room";
        zone = "foxden.network";
      };
      mac = "EC:F4:51:D0:8C:AF";
      addresses = [
        "10.2.12.10/16"
      ];
    };
    capefox-wired = mkIntf {
      dns = {
        name = "capefox-wired";
        zone = "foxden.network";
      };
      mac = "00:30:93:12:12:38";
      addresses = [
        "10.2.10.4/16"
        "fd2c:f4cb:63be:2::0a04/64"
      ];
    };
    camera-front-door = mkIntf {
      dns = {
        name = "camera-front-door";
        zone = "foxden.network";
      };
      mac = "E4:38:83:0E:1F:D3";
      addresses = [
        "10.5.11.1/16"
      ];
    };
    tesla-wall-charger = mkIntf {
      dns = {
        name = "tesla-wall-charger";
        zone = "foxden.network";
      };
      mac = "98:ED:5C:9B:79:CF";
      addresses = [
        "10.2.12.16/16"
      ];
    };
    nvr = mkIntf {
      dns = {
        name = "nvr";
        zone = "foxden.network";
      };
      mac = "60:22:32:F1:BF:71";
      addresses = [
        "10.5.10.1/16"
        "fd2c:f4cb:63be:5::0a01/64"
      ];
    };
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
    hue-sync-box = mkIntf {
      dns = {
        name = "hue-sync-box";
        zone = "foxden.network";
      };
      mac = "C4:29:96:0B:9C:82";
      addresses = [
        "10.2.12.18/16"
      ];
    };
    camera-back-right = mkIntf {
      dns = {
        name = "camera-back-right";
        zone = "foxden.network";
      };
      mac = "D0:21:F9:99:60:DA";
      addresses = [
        "10.5.11.4/16"
      ];
    };
    camera-front-right = mkIntf {
      dns = {
        name = "camera-front-right";
        zone = "foxden.network";
      };
      mac = "70:A7:41:5F:DB:54";
      addresses = [
        "10.5.11.3/16"
      ];
    };
    camera-front-left = mkIntf {
      dns = {
        name = "camera-front-left";
        zone = "foxden.network";
      };
      mac = "70:A7:41:0B:11:36";
      addresses = [
        "10.5.11.5/16"
      ];
    };
    nanoleaf-lines-wizzy = mkIntf {
      dns = {
        name = "nanoleaf-lines-wizzy";
        zone = "foxden.network";
      };
      mac = "80:8A:F7:03:55:58";
      addresses = [
        "10.2.12.19/16"
      ];
    };
    ap-living-room = mkIntf {
      dns = {
        name = "ap-living-room";
        zone = "foxden.network";
      };
      mac = "60:22:32:83:6D:9E";
      addresses = [
        "10.1.10.11/16"
      ];
    };
    nanoleaf-shapes-dori = mkIntf {
      dns = {
        name = "nanoleaf-shapes-dori";
        zone = "foxden.network";
      };
      mac = "80:8A:F7:03:E2:1A";
      addresses = [
        "10.2.12.28/16"
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
    switch-living-room = mkIntf {
      dns = {
        name = "switch-living-room";
        zone = "foxden.network";
      };
      mac = "E4:38:83:8C:AA:DA";
      addresses = [
        "10.1.10.13/16"
      ];
    };
    switch-rack = mkIntf {
      dns = {
        name = "switch-rack";
        zone = "foxden.network";
      };
      mac = "D8:B3:70:1E:9E:3A";
      addresses = [
        "10.1.10.12/16"
      ];
    };
    switch-dori-office = mkIntf {
      dns = {
        name = "switch-dori-office";
        zone = "foxden.network";
      };
      mac = "60:22:32:39:77:9C";
      addresses = [
        "10.1.10.5/16"
      ];
    };
    camera-back-door-upper = mkIntf {
      dns = {
        name = "camera-back-door-upper";
        zone = "foxden.network";
      };
      mac = "D0:21:F9:94:97:13";
      addresses = [
        "10.5.11.6/16"
      ];
    };
    switch-den-desk = mkIntf {
      dns = {
        name = "switch-den-desk";
        zone = "foxden.network";
      };
      mac = "74:83:C2:FF:87:16";
      addresses = [
        "10.1.10.14/16"
      ];
    };
    camera-den = mkIntf {
      dns = {
        name = "camera-den";
        zone = "foxden.network";
      };
      mac = "E4:38:83:0E:E4:A3";
      addresses = [
        "10.5.11.7/16"
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
    streamdeckpi = mkIntf {
      dns = {
        name = "streamdeckpi";
        zone = "foxden.network";
      };
      mac = "D8:3A:DD:40:CA:F1";
      addresses = [
        "10.2.12.30/16"
      ];
    };
    camera-garage = mkIntf {
      dns = {
        name = "camera-garage";
        zone = "foxden.network";
      };
      mac = "F4:E2:C6:0C:3F:C3";
      addresses = [
        "10.5.11.8/16"
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
    ecoflow-delta-pro = mkIntf {
      dns = {
        name = "ecoflow-delta-pro";
        zone = "foxden.network";
      };
      mac = "4C:EB:D6:D6:3C:9C";
      addresses = [
        "10.2.12.31/16"
      ];
    };
    switch-dori-office-tv = mkIntf {
      dns = {
        name = "switch-dori-office-tv";
        zone = "foxden.network";
      };
      mac = "F4:E2:C6:AC:81:3D";
      addresses = [
        "10.1.10.15/16"
      ];
    };
    switch-dori-office-desk = mkIntf {
      dns = {
        name = "switch-dori-office-desk";
        zone = "foxden.network";
      };
      mac = "F4:E2:C6:AC:81:DC";
      addresses = [
        "10.1.10.16/16"
      ];
    };
    camera-server-room = mkIntf {
      dns = {
        name = "camera-server-room";
        zone = "foxden.network";
      };
      mac = "F4:E2:C6:0C:E8:3C";
      addresses = [
        "10.5.11.9/16"
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
    crossfox = mkIntf {
      dns = {
        name = "crossfox";
        zone = "foxden.network";
      };
      mac = "B8:27:EB:ED:0F:4B";
      addresses = [
        "10.5.10.3/16"
        "fd2c:f4cb:63be:5::0a03/64"
      ];
    };
    led-strip-dori-office-ceiling = mkIntf {
      dns = {
        name = "led-strip-dori-office-ceiling";
        zone = "foxden.network";
      };
      mac = "C4:DE:E2:B2:D2:C7";
      addresses = [
        "10.2.13.21/16"
      ];
    };
    camera-side-right = mkIntf {
      dns = {
        name = "camera-side-right";
        zone = "foxden.network";
      };
      mac = "1C:6A:1B:81:B9:D4";
      addresses = [
        "10.5.11.10/16"
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
