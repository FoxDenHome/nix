{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = "prometheus";
    group = "prometheus";
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.prometheus;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;

  cfgObj = {
    global = {
      scrape_interval = "60s";
      evaluation_interval = "60s";
      external_labels = {
        monitor = hostName;
      };
    };
    scrape_config_files = [
      "/tmp/prometheus-scrape/*.yml"
      "/etc/prometheus-scrape/*.yml"
    ];
  };
in
{
  options.foxDen.services.prometheus = {

  } // services.mkOptions { svcName = "prometheus"; name = "Prometheus monitoring server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "prometheus";
      inherit svcConfig pkgs config;
    }).config
    {
      services.prometheus = {
        enable = true;
        stateDir = "prometheus";
        configText = builtins.toJSON cfgObj;
      };

      sops.secrets.prometheus = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "prometheus";
        group = "prometheus";
      };

      systemd.services.prometheus = {
        confinement.packages = [
          pkgs.coreutils
        ];

        serviceConfig = {
          BindReadOnlyPaths = [
            "${./prometheus-scrape}:/etc/prometheus-scrape"
          ];
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p /tmp/prometheus-scrape"
            "${pkgs.bash}/bin/bash -c '${pkgs.gnused}/bin/sed \"s~__HOMEASSISTANT_API_TOKEN__~$HOMEASSISTANT_API_TOKEN~\" < ${./prometheus-scrape/homeassistant.yml.tpl} > /tmp/prometheus-scrape/homeassistant.yml'"
          ];
          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.prometheus.path;
        };
      };

      environment.persistence."/nix/persist/prometheus" = {
        hideMounts = true;
        directories = [
          (mkDir "/var/lib/prometheus")
        ];
      };
    }
  ]);
}
