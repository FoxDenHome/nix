{
  rootDiskSize = "64G";
  autostart = true;
  interfaces.default = {
    driver = "null";
    dns = {
      name = "homeassistant.foxden.network";
      dynDns = true;
    };
    webservice = {
      enable = true;
      proxyProtocol = false;
    };
    mac = "52:54:00:e9:7e:50";
    addresses = [
      "10.2.12.2/16"
      "fd2c:f4cb:63be:2::c02/64"
    ];
  };
}
