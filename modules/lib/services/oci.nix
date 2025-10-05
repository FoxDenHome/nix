{ foxDenLib, nixpkgs, ... }:
let
    mkNamed = (svc: inputs@{ oci, systemd, svcConfig, pkgs, config, ... }: (foxDenLib.services.mkNamed svc inputs) // (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
    in {
      config.virtualisation.oci-containers.containers."${svc}" = nixpkgs.lib.mkMerge [
        {
          autoStart = nixpkgs.lib.mkDefault true;
          pull = nixpkgs.lib.mkDefault "always";
          networks = [ "ns:${host.namespacePath}" ];

          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "/etc/locale.conf:/etc/locale.conf:ro"
          ];
          environment = {
            "TZ" = config.time.timeZone;
            "LANG" = config.i18n.defaultLocale;
          };
        }
        oci
      ];

      config.systemd.services."podman-${svc}" = nixpkgs.lib.mkMerge [
        {
          requires = [ host.unit ];
          bindsTo = [ host.unit ];
          after = [ host.unit ];
        }
        systemd
      ];
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;
}
