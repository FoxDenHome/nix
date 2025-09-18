{ ... }:
{
  make = ({ name, config, ... }:
    let
      host = config.foxDen.hosts.${name};
      info = config.foxDen.hostInfo.${name};
    in
    {
      host = host;
      info = info;
      enable = host != null;

      systemd.serviceConfig = {
        Slice = "${info.slice}.slice";
        DevicePolicy = "closed";
        PrivateTmp = true;
        PrivateMount = true;
      };
    });
}
