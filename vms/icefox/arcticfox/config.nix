{
  rootDiskSize = "128G";
  autostart = true;
  interface = {
    dns = {
      name = "arcticfox";
      zone = "doridian.net";
    };
    cnames = [
      {
        name = "pma";
        zone = "doridian.net";
      }
      {
        name = "ftp";
        zone = "doridian.net";
      }
      {
        name = "mail";
        zone = "doridian.net";
      }
      {
        name = "www.pma";
        zone = "doridian.net";
      }
      {
        name = "www.ftp";
        zone = "doridian.net";
      }
      {
        name = "www.mail";
        zone = "doridian.net";
      }
    ];
    addresses = [
      "95.216.116.135/26"
      "2a01:4f9:2b:1a42::0:ff01/112"
    ];
    mac = "00:50:56:00:D8:C7";
  };
  records = [
    {
      zone = "doridian.net";
      name = "arcticfox";
      type = "TXT";
      ttl = 3600;
      value = "v=spf1 +a:arcticfox.doridian.net include:amazonses.com mx ~all";
      horizon = "*";
    }
    {
      zone = "doridian.net";
      name = "_dmarc.arcticfox";
      type = "TXT";
      ttl = 3600;
      value = "v=DMARC1;p=quarantine;pct=100";
      horizon = "*";
    }
  ];
}
