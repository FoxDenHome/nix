{ ... }:
{
  config = ({ name, config, ... }:
    let
      host = config.foxDen.hosts.${name};
      info = config.foxDen.hostInfo.${name};
    in
    {
      host = host;
      info = info;
      slice = "${info.slice}.slice";
      enable = host != null;
    });
}
