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
        RestrictNetworkInterfaces = info.serviceInterface;
        DevicePolicy = "closed";
        PrivateTmp = true;
        PrivateMounts = true;
        #PrivateNetwork = true;
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        ReadOnlyPaths = ["/"];
      };
    });
}
