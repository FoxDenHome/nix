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

      systemd.unitConfig = {
        Requires = info.requires;
        BindsTo = info.requires;
        After = info.requires;
      };

      systemd.serviceConfig = {
        NetworkNamespacePath = info.namespace;
        DevicePolicy = "closed";
        PrivateTmp = true;
        PrivateMounts = true;
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        ReadOnlyPaths = ["/"];
      };
    });
}
