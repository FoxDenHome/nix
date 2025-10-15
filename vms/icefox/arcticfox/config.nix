{
  rootDiskSize = "128G";
  autostart = true;
  interface = {
    dns = {
      name = "arcticfox";
      zone = "doridian.net";
    };
    addresses = [
      "95.216.116.135/26"
      "2a01:4f9:2b:1a42::0:ff01/112"
    ];
    mac = "00:50:56:00:D8:C7";
  };
  records = map(name: {
      zone = "doridian.net";
      name = name;
      type = "CNAME";
      ttl = 3600;
      value = "arcticfox.doridian.net.";
      horizon = "*";
    }) [
      "pma"
      "ftp"
      "mail"
      "www.pma"
      "www.ftp"
      "www.mail"
    ];
}
