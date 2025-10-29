{
  rootDiskSize = "80G";
  autostart = true;
  interfaces.default = {
    dns = {
      name = "bengalfox-win.foxden.network";
    };
    addresses = [
      "10.2.10.10/16"
      "fd2c:f4cb:63be:2::a0a/64"
    ];
    mac = "5e:8c:f2:cd:c8:4a";
  };
}
