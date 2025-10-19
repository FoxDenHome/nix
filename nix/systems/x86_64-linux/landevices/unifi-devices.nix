{ foxDenLib, ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
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
      firewall.ingressAcceptRules = foxDenLib.firewall.templates.trusted "nvr";
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
  };
}
