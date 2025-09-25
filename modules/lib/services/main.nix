{ nixpkgs, foxDenLib, ... }:
let
  mkNamed = (svc: { svcConfig, config, ... }:
  let
    host = foxDenLib.hosts.getByName config svcConfig.host;
  in
  {
    configDir = "/etc/foxden/services/${svc}";
    # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test

    config = {
      systemd.services.${svc} = {
        confinement.enable = true;

        unitConfig = {
          Requires = [ host.unit ];
          BindsTo = [ host.unit ];
          After = [ host.unit ];
        };

        serviceConfig = {
          NetworkNamespacePath = host.namespace;
          DevicePolicy = "closed";
          PrivateDevices = nixpkgs.lib.mkForce true;
          Restart = nixpkgs.lib.mkForce "always";

          BindReadOnlyPaths = [
            "/run/systemd/notify"
            "/nix/store"
            "${host.resolvConf}:/etc/resolv.conf"
            "-/etc/hosts"
            "-/etc/localtime"
            "-/etc/passwd"
            "-/etc/group"
            "-/etc/pki/tls/certs"
            "-/etc/ssl/certs"
            "-/etc/static/pki/tls/certs"
            "-/etc/static/ssl/certs"
          ];
        };
      };
    };
  });
in
{
  mkOptions = { name, svcName }: {
    enable = nixpkgs.lib.mkEnableOption name;
    host = nixpkgs.lib.mkOption {
      type = nixpkgs.lib.types.str;
    };
  };

  make = (inputs@{ svcConfig, ... }: mkNamed (inputs.name or svcConfig.host) inputs);
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
