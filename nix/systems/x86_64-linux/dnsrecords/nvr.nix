{ ... } :
{
  config.foxDen.hosts.hosts = let
    mkIntf = (intf: {
      interfaces.default = { driver = "null"; } // intf;
    });
  in {
    nvr = mkIntf {
      dns = {
        name = "nvr";
        zone = "foxden.network";
        dynDns = true;
      };
      addresses = [
        "10.5.10.1/16"
        "fd2c:f4cb:63be:5::a01/64"
      ];
    };
  };
}
