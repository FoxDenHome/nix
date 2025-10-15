{
  rootDiskSize = "64G";
  autostart = true;
  interface = {
    driver = "null";
    dns = {
      name = "homeassistant";
      zone = "foxden.network";
      dynDns = true;
    };
    addresses = [
      "10.2.12.2/16"
      "fd2c:f4cb:63be:2::c02/64"
    ];
  };
}
