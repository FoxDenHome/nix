{ foxDenLib, nixpkgs, ... }:
let
    mkNamed = (svc: inputs@{ oci, systemd ? {}, svcConfig, pkgs, config, ... }: (let
      systemdName = "podman-${svc}";
    in {
      config = nixpkgs.lib.mkMerge [
        (foxDenLib.services.mkNamed systemdName inputs).config
        {
          virtualisation.oci-containers.containers."${svc}" = nixpkgs.lib.mkMerge [
            {
              autoStart = nixpkgs.lib.mkDefault true;
              pull = nixpkgs.lib.mkDefault "always";
              networks = [ "host" ];

              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                "/etc/locale.conf:/etc/locale.conf:ro"
              ];
              environment = {
                "TZ" = config.time.timeZone;
                "LANG" = config.i18n.defaultLocale;
              };

              podman = {
                user = svc;
              };
            }
            oci
          ];

          users.users."${svc}" = {
            isSystemUser = true;
            group = svc;
            autoSubUidGidRange = true;
            home = "/var/lib/foxden-oci/${svc}";
            createHome = true;
          };
          users.groups."${svc}" = {};

          systemd.services.${systemdName} = nixpkgs.lib.mkMerge [
            {
              confinement.packages = [
                pkgs.coreutils
                pkgs.podman
              ];

              path = [
                pkgs.coreutils
                pkgs.podman
              ];
            }
            systemd
          ];
        }
      ];
    }));
in
{
  mkOptions = inputs: foxDenLib.services.mkOptions inputs;
  mkNamed = mkNamed;
  make = inputs: mkNamed inputs.name inputs;

  nixosModule = { ... }:
  {
    config.environment.persistence."/nix/persist/oci" = {
      hideMounts = true;
      directories = [
        "/var/lib/containers"
        "/var/lib/foxden-oci"
      ];
    };

    config.virtualisation.oci-containers.backend = "podman";

    config.virtualisation.podman.autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
}
