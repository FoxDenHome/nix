{ nixpkgs, foxDenLib, ... }:
let
  hosts = foxDenLib.hosts;

  mkNamed = (svc: { svcConfig, ... }:
  let
    info = hosts.mkHostInfo svcConfig.host;
  in
  {
    # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test
    systemd.services.${svc} = {
      unitConfig = {
        Requires = [ info.unit ];
        BindsTo = [ info.unit ];
        After = [ info.unit ];
      };

      serviceConfig = {
        NetworkNamespacePath = info.namespace;
        DevicePolicy = "closed";
        PrivateTmp = true;
        PrivateMounts = true;
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        Restart = nixpkgs.lib.mkForce "always";
      };
    };

    foxDen.hosts.hosts = nixpkgs.lib.mkIf (svcConfig.host != null) [svcConfig.host];
  });
in
{
  mkOptions = { name, svcName }: {
    enable = nixpkgs.lib.mkEnableOption name;
    host = hosts.mkOption {
      nameDef = svcName;
    };
  };

  make = (inputs@{ svcConfig, ... }: mkNamed (inputs.name or svcConfig.host.name) inputs);
  mkNamed = mkNamed;
}
