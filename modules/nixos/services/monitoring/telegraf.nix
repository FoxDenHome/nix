{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.telegraf;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
in
{
  options.foxDen.services.telegraf = {

  } // services.mkOptions { svcName = "telegraf"; name = "Telegraf monitoring agent"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "telegraf";
      inherit svcConfig pkgs config;
    }).config
    {
      services.telegraf = let
        cfgs = lib.attrsets.attrNames (builtins.readDir ./telegraf.conf.d);

        cfgRead = map (name: builtins.fromTOML (builtins.readFile ./telegraf.conf.d/${name})) cfgs;
      in
        {
          enable = true;
          extraConfig = lib.mkMerge (cfgRead ++ [{
            agent = {
              interval = "10s";
              round_interval = true;
              metric_batch_size = 1000;
              metric_buffer_limit = 10000;
              collection_jitter = "0s";
              flush_interval = "10s";
              flush_jitter = "0s";
              precision = "";
              hostname = hostName;
              omit_hostname = false;
              snmp_translator = "gosmi";
            };
            outputs = {
              prometheus_client = {
                listen = ":9273";
                metric_version = 2;
                expiration_interval = "60s";
                export_timestamp = true;
              };
            };
          }]);
        };

      sops.secrets.telegraf = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "telegraf";
        group = "telegraf";
      };

      systemd.services.telegraf = {
        confinement.packages = [
          pkgs.coreutils
        ];

        serviceConfig = {
          BindReadOnlyPaths = [
            "${./mibs}:/usr/share/snmp/mibs"
          ];
          EnvironmentFile = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.telegraf.path;
        };
      };
    }
  ]);
}
