{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.prometheus.user;
    group = config.services.prometheus.group;
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
      "/tmp/scrape_configs/*.yml"
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
        stateDir = "/var/lib/prometheus";
        configText = builtins.toYAML cfgObj;
      };

      sops.secrets.prometheus = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "prometheus";
        group = "prometheus";
      };

      systemd.services.prometheus = {
        serviceConfig = {
          ExecStartPre = [
            "${pkgs.mkdir}/bin/mkdir -p /tmp/scrape_configs"
            "${pkgs.bash}/bin/bash -c '${pkgs.gnused}/bin/sed \"s~__HOMEASSISTANT_API_TOKEN__~$HOMEASSISTANT_API_TOKEN~\" < ${./prometheus-scrape.yml} > /tmp/scrape_configs/prometheus-scrape.yml'"
          ];
          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.prometheus.path;
          StateDirectory = "prometheus";
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
