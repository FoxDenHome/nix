{ nixpkgs, foxDenLib, ... }:
let
  mkEtcPaths = (paths: nixpkgs.lib.flatten (
    map (path: [
      ("-/etc/" + path)
      ("-/etc/static/" + path)
    ]) paths
  ));

  mkNamed = (svc: { svcConfig, pkgs, config, gpu ? false, ... }:
  let
    host = foxDenLib.hosts.getByName config svcConfig.host;

    dependency = if svcConfig.host != "" then [ host.unit ] else [];
    resolvConf = if svcConfig.host != "" then host.resolvConf else "/etc/resolv.conf";

    gpuPackages = if gpu then [
      config.hardware.graphics.package
    ] ++ config.hardware.graphics.extraPackages else [];
    gpuPaths = if gpu then [
      "-/run/opengl-driver"
      "-/run/opengl-driver-32"
    ] else [];
  in
  {
    configDir = "/etc/foxden/services/${svc}";

    config = {
      systemd.services.${svc} = {
        confinement.enable = true;
        confinement.packages = [
          pkgs.cacert
        ] ++ gpuPackages;

        requires = dependency;
        bindsTo = dependency;
        after = dependency;

        serviceConfig = {
          NetworkNamespacePath = nixpkgs.lib.mkIf (svcConfig.host != "") host.namespacePath;
          DevicePolicy = nixpkgs.lib.mkForce "closed";
          PrivateDevices = nixpkgs.lib.mkForce false;
          DeviceAllow = nixpkgs.lib.mkIf gpu (map (dev: "${dev} rwm") config.foxDen.services.gpuDevices);
          ProtectProc = "invisible";
          Restart = nixpkgs.lib.mkDefault "always";

          BindReadOnlyPaths = [
            "/run/systemd/notify"
            "${resolvConf}:/etc/resolv.conf"
          ] ++ gpuPaths ++ mkEtcPaths [
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
    config.environment.persistence."/nix/persist/foxden/services" = {
      hideMounts = true;
      directories = [
        { directory = "/var/lib/private"; user = "root"; group = "root"; mode = "u=rwx,g=,o="; }
        { directory = "/var/cache/private"; user = "root"; group = "root"; mode = "u=rwx,g=,o="; }
      ];
    };

    options.foxDen.services.gpuDevices = nixpkgs.lib.mkOption {
      type = nixpkgs.lib.types.listOf nixpkgs.lib.types.str;
      default = [ ];
    };
  };
}
