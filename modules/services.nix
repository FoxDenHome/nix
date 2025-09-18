{ ... }:
{
  mkHostService = ({ name, config, ... }:
    let
      host = config.foxDen.hosts.${name};
      info = config.foxDen.hostInfo.${name};
    in
    {
      host = host;
      info = info;
      enabled = (config.foxDen.hosts.${name} or null) != null;

      slice = {
        description = "Slice for ${name}";
        sliceConfig = {
          RestrictNetworkInterfaces = info.serviceInterface;
          PrivateNetwork = true;
        };
      };
    });
}
