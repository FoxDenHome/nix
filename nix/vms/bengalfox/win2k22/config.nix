{
  rootDiskSize = "80G";
  autostart = true;
  interfaces.default = {
    dns = {
      name = "bengalfox-win.foxden.network";
    };
    addresses = [
      "10.2.10.10/16"
    ];
    mac = "5e:8c:f2:cd:c8:4a";
    dhcpv6 = {
      duid = "0x000100013078e51e5e8cf2cdc84a";
      iaid = 106058752;
    };
  };
}
