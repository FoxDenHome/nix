{ ... }:
{
  make = ({ name, config, ... }:
    let
      host = config.foxDen.hosts.hosts.${name};
      info = config.foxDen.hosts.info.${name};
    in
    {
      host = host;
      info = info;
      enable = host != null;

      oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test

      systemd.unitConfig = {
        Requires = [ info.unit ];
        BindsTo = [ info.unit ];
        After = [ info.unit ];
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
