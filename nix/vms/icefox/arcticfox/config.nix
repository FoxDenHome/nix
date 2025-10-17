{
  rootDiskSize = "128G";
  autostart = true;
  interfaces = let
    dns = {
      name = "arcticfox";
      zone = "doridian.net";
    };
    cnames = [
      {
        name = "pma.arcticfox";
        zone = "doridian.net";
      }
      {
        name = "ftp.arcticfox";
        zone = "doridian.net";
      }
      {
        name = "mail.arcticfox";
        zone = "doridian.net";
      }
      {
        name = "www.pma.arcticfox";
        zone = "doridian.net";
      }
      {
        name = "www.ftp.arcticfox";
        zone = "doridian.net";
      }
      {
        name = "www.mail.arcticfox";
        zone = "doridian.net";
      }
    ];
  in {
    default = {
      inherit dns cnames;
      addresses = [
        "95.216.116.135/26"
        "2a01:4f9:2b:1a42::0:f1/112"
      ];
      mac = "00:50:56:00:D8:C7";
    };
    foxden = {
      inherit dns cnames;
      addresses = [
        "10.99.12.241/24"
        "fd2c:f4cb:63be::a63:f1/112"
      ];
      mac = "00:50:56:00:D8:C8";
    };
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
