{
  rootDiskSize = "64G";
  interface = {
    driver = "null";
    dns = {
      name = "homeassistant";
      zone = "foxden.network";
    };
    addresses = [
      "10.2.12.2/16"
      "fd2c:f4cb:63be:2::c02/64"
    ];
  };
}
