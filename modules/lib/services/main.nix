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

    dependency = if svcConfig.host != "" then [ host.unit ] else [];
    resolvConf = if svcConfig.host != "" then host.resolvConf else "/etc/resolv.conf";
  in
  {
    configDir = "/etc/foxden/services/${svc}";

    config = {
      systemd.services.${svc} = {
        confinement.enable = true;
        confinement.packages = [
          pkgs.cacert
        ];

        requires = dependency;
        bindsTo = dependency;
        after = dependency;

        serviceConfig = {
          NetworkNamespacePath = nixpkgs.lib.mkIf (svcConfig.host != "") host.namespacePath;
          DevicePolicy = "closed";
          PrivateDevices = nixpkgs.lib.mkForce true;
          ProtectProc = "invisible";
          Restart = nixpkgs.lib.mkDefault "always";

          BindReadOnlyPaths = [
            "/run/systemd/notify"
            "${resolvConf}:/etc/resolv.conf"
          ] ++ mkEtcPaths [
            "hosts"
            "localtime"
            "locale.conf"
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
