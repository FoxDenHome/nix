{ foxDenLib, nixpkgs, ... }:
let
    mkNamed = (ctName: { oci, systemd ? {}, svcConfig, pkgs, config, ... }: (let
      host = foxDenLib.hosts.getByName config svcConfig.host;
      dependency = if svcConfig.host != "" then [ host.unit ] else [];
      systemdName = "podman-${ctName}";
    in {
      config = {
        virtualisation.oci-containers.containers."${ctName}" = nixpkgs.lib.mkMerge [
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
              user = ctName;
            };
          }
          oci
        ];

        users.users."${ctName}" = {
          isSystemUser = true;
          group = ctName;
          autoSubUidGidRange = true;
          home = "/var/lib/foxden-oci/${ctName}";
          createHome = true;
        };
        users.groups."${ctName}" = {};

        systemd.services.${systemdName} = nixpkgs.lib.mkMerge [
          {
            requires = dependency;
            bindsTo = dependency;
            after = dependency;

            serviceConfig = {
              NetworkNamespacePath = nixpkgs.lib.mkIf (svcConfig.host != "") host.namespacePath;
              Restart = nixpkgs.lib.mkDefault "always";
            };
          }
          systemd
        ];
      };
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
