{ nixpkgs, foxDenLib, ... }:
let
  hosts = foxDenLib.hosts;

  mkNamed = (svc: { svcConfig, config, ... }:
  let
    info = hosts.mkHostInfo svcConfig.host;
  in
  {
    configDir = "/etc/foxden/services/${svc}";
    # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test

    config = {
      systemd.services.${svc} = {
        unitConfig = {
          Requires = [ info.unit ];
          BindsTo = [ info.unit ];
          After = [ info.unit ];
        };

        serviceConfig = {
          TemporaryFileSystem = ["/:ro"];
          NetworkNamespacePath = info.namespace;
          DevicePolicy = "closed";
          PrivateTmp = true;
          PrivateMounts = true;
          Restart = nixpkgs.lib.mkForce "always";
          BindReadOnlyPaths = [
            "/run/systemd/notify"
            "/nix/store"
            "${info.resolvConf}:/etc/resolv.conf"
            "-/etc/nsswitch.conf"
            "-/etc/hosts"
            "-/etc/localtime"
            "-/etc/passwd"
            "-/etc/group"
          ];
        };
      };

      foxDen.hosts.hosts = nixpkgs.lib.mkIf (svcConfig.host != null) [svcConfig.host];
    };
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

  nixosModule = { ... }:
  {
    environment.persistence."/nix/persist/foxden/services" = {
      hideMounts = true;
      directories = [
        { directory = "/var/lib/private"; user = "root"; group = "root"; mode = "u=rwx,g=,o="; }
      ];
    };
  };
}
