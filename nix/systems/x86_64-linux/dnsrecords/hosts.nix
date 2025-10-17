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
      addresses = [
        "10.1.11.1/16"
        "fd2c:f4cb:63be:1::0b01/64"
      ];
    };
    switch-den = mkIntf {
      dns = {
        name = "switch-den";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.2/16"
        "fd2c:f4cb:63be:1::0a02/64"
      ];
    };
    switch-rack-agg = mkIntf {
      dns = {
        name = "switch-rack-agg";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.3/16"
        "fd2c:f4cb:63be:1::0a03/64"
      ];
    };
    ups-rack = mkIntf {
      dns = {
        name = "ups-rack";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.11.2/16"
        "fd2c:f4cb:63be:1::0b02/64"
      ];
    };
    ap-backyard = mkIntf {
      dns = {
        name = "ap-backyard";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.6/16"
        "fd2c:f4cb:63be:1::0a06/64"
      ];
    };
    ap-corridor-upper = mkIntf {
      dns = {
        name = "ap-corridor-upper";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.7/16"
        "fd2c:f4cb:63be:1::0a07/64"
      ];
    };
    switch-dori-office-agg = mkIntf {
      dns = {
        name = "switch-dori-office-agg";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.10/16"
        "fd2c:f4cb:63be:1::0a0a/64"
      ];
    };
    ups-dori-office = mkIntf {
      dns = {
        name = "ups-dori-office";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.11.3/16"
        "fd2c:f4cb:63be:1::0b03/64"
      ];
    };
    printer = mkIntf {
      dns = {
        name = "printer";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.3/16"
        "fd2c:f4cb:63be:2::0c03/64"
      ];
    };
    hue = mkIntf {
      dns = {
        name = "hue";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.1/16"
        "fd2c:f4cb:63be:2::0c01/64"
      ];
    };
    camera-living-room = mkIntf {
      dns = {
        name = "camera-living-room";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.2/16"
        "fd2c:f4cb:63be:5::0b02/64"
      ];
    };
    amp-living-room = mkIntf {
      dns = {
        name = "amp-living-room";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.10/16"
        "fd2c:f4cb:63be:2::0c0a/64"
      ];
    };
    capefox-wired = mkIntf {
      dns = {
        name = "capefox-wired";
        zone = "foxden.network";
      };
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
      addresses = [
        "10.5.11.1/16"
        "fd2c:f4cb:63be:5::0b01/64"
      ];
    };
    tesla-wall-charger = mkIntf {
      dns = {
        name = "tesla-wall-charger";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.16/16"
        "fd2c:f4cb:63be:2::0c10/64"
      ];
    };
    nvr = mkIntf {
      dns = {
        name = "nvr";
        zone = "foxden.network";
      };
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
      addresses = [
        "10.4.10.1/16"
        "fd2c:f4cb:63be:4::0a01/64"
      ];
    };
    hue-sync-box = mkIntf {
      dns = {
        name = "hue-sync-box";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.18/16"
        "fd2c:f4cb:63be:2::0c12/64"
      ];
    };
    camera-back-right = mkIntf {
      dns = {
        name = "camera-back-right";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.4/16"
        "fd2c:f4cb:63be:5::0b04/64"
      ];
    };
    camera-front-right = mkIntf {
      dns = {
        name = "camera-front-right";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.3/16"
        "fd2c:f4cb:63be:5::0b03/64"
      ];
    };
    camera-front-left = mkIntf {
      dns = {
        name = "camera-front-left";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.5/16"
        "fd2c:f4cb:63be:5::0b05/64"
      ];
    };
    nanoleaf-lines-wizzy = mkIntf {
      dns = {
        name = "nanoleaf-lines-wizzy";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.19/16"
        "fd2c:f4cb:63be:2::0c13/64"
      ];
    };
    ap-living-room = mkIntf {
      dns = {
        name = "ap-living-room";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.11/16"
        "fd2c:f4cb:63be:1::0a0b/64"
      ];
    };
    nanoleaf-shapes-dori = mkIntf {
      dns = {
        name = "nanoleaf-shapes-dori";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.28/16"
        "fd2c:f4cb:63be:2::0c1c/64"
      ];
    };
    carvera-controller = mkIntf {
      dns = {
        name = "carvera-controller";
        zone = "foxden.network";
      };
      addresses = [
        "10.4.10.2/16"
        "fd2c:f4cb:63be:4::0a02/64"
      ];
    };
    hue-upstairs = mkIntf {
      dns = {
        name = "hue-upstairs";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.27/16"
        "fd2c:f4cb:63be:2::0c1b/64"
      ];
    };
    switch-living-room = mkIntf {
      dns = {
        name = "switch-living-room";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.13/16"
        "fd2c:f4cb:63be:1::0a0d/64"
      ];
    };
    switch-rack = mkIntf {
      dns = {
        name = "switch-rack";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.12/16"
        "fd2c:f4cb:63be:1::0a0c/64"
      ];
    };
    switch-dori-office = mkIntf {
      dns = {
        name = "switch-dori-office";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.5/16"
        "fd2c:f4cb:63be:1::0a05/64"
      ];
    };
    camera-back-door-upper = mkIntf {
      dns = {
        name = "camera-back-door-upper";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.6/16"
        "fd2c:f4cb:63be:5::0b06/64"
      ];
    };
    switch-den-desk = mkIntf {
      dns = {
        name = "switch-den-desk";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.14/16"
        "fd2c:f4cb:63be:1::0a0e/64"
      ];
    };
    camera-den = mkIntf {
      dns = {
        name = "camera-den";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.7/16"
        "fd2c:f4cb:63be:5::0b07/64"
      ];
    };
    carvera = mkIntf {
      dns = {
        name = "carvera";
        zone = "foxden.network";
      };
      addresses = [
        "10.4.10.3/16"
        "fd2c:f4cb:63be:4::0a03/64"
      ];
    };
    wii = mkIntf {
      dns = {
        name = "wii";
        zone = "foxden.network";
      };
      addresses = [
        "100.96.41.101/24"
      ];
    };
    tape-library = mkIntf {
      dns = {
        name = "tape-library";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.13.1/16"
        "fd2c:f4cb:63be:1::0d01/64"
      ];
    };
    ps2 = mkIntf {
      dns = {
        name = "ps2";
        zone = "foxden.network";
      };
      addresses = [
        "100.96.41.102/24"
      ];
    };
    streamdeckpi = mkIntf {
      dns = {
        name = "streamdeckpi";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.30/16"
        "fd2c:f4cb:63be:2::0c1e/64"
      ];
    };
    camera-garage = mkIntf {
      dns = {
        name = "camera-garage";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.8/16"
        "fd2c:f4cb:63be:5::0b08/64"
      ];
    };
    laser-controller = mkIntf {
      dns = {
        name = "laser-controller";
        zone = "foxden.network";
      };
      addresses = [
        "10.4.10.5/16"
        "fd2c:f4cb:63be:4::0a05/64"
      ];
    };
    ecoflow-delta-pro = mkIntf {
      dns = {
        name = "ecoflow-delta-pro";
        zone = "foxden.network";
      };
      addresses = [
        "10.2.12.31/16"
        "fd2c:f4cb:63be:2::0c1f/64"
      ];
    };
    switch-dori-office-tv = mkIntf {
      dns = {
        name = "switch-dori-office-tv";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.15/16"
        "fd2c:f4cb:63be:1::0a0f/64"
      ];
    };
    switch-dori-office-desk = mkIntf {
      dns = {
        name = "switch-dori-office-desk";
        zone = "foxden.network";
      };
      addresses = [
        "10.1.10.16/16"
        "fd2c:f4cb:63be:1::0a10/64"
      ];
    };
    camera-server-room = mkIntf {
      dns = {
        name = "camera-server-room";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.9/16"
        "fd2c:f4cb:63be:5::0b09/64"
      ];
    };
    pikvm-rack = mkIntf {
      dns = {
        name = "pikvm-rack";
        zone = "foxden.network";
      };
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
      addresses = [
        "10.2.13.21/16"
        "fd2c:f4cb:63be:2::0d15/64"
      ];
    };
    camera-side-right = mkIntf {
      dns = {
        name = "camera-side-right";
        zone = "foxden.network";
      };
      addresses = [
        "10.5.11.10/16"
        "fd2c:f4cb:63be:5::0b0a/64"
      ];
    };
    mister = mkIntf {
      dns = {
        name = "mister";
        zone = "foxden.network";
      };
      addresses = [
        "100.96.41.253/24"
      ];
    };
  };
}
