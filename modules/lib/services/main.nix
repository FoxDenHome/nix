{ nixpkgs, foxDenLib, ... }:
let
  mkEtcPaths = (paths: nixpkgs.lib.flatten (
    map (path: [
      ("-/etc/" + path)
      ("-/etc/static/" + path)
    ]) paths
  ));

  mkNamed = (svc: { svcConfig, pkgs, config, ... }:
  let
    host = foxDenLib.hosts.getByName config svcConfig.host;
  in
  {
    configDir = "/etc/foxden/services/${svc}";
    # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test

    config = {
      systemd.services.${svc} = {
        confinement.enable = true;
        confinement.packages = [
          pkgs.nss-cacert
        ];

        unitConfig = {
          Requires = [ host.unit ];
          BindsTo = [ host.unit ];
          After = [ host.unit ];
        };

        serviceConfig = {
          NetworkNamespacePath = host.namespacePath;
          DevicePolicy = "closed";
          PrivateDevices = nixpkgs.lib.mkForce true;
          Restart = nixpkgs.lib.mkForce "always";

          BindReadOnlyPaths = [
            "/run/systemd/notify"
            "${host.resolvConf}:/etc/resolv.conf"
          ] ++ mkEtcPaths [
            "hosts"
            "localtime"
            "passwd"
            "group"
            "pki/tls/certs"
            "ssl/certs"
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

  mkEtcPaths = mkEtcPaths;

  make = inputs: mkNamed inputs.name inputs;
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
