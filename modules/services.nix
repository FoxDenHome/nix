{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;

  make = (svc: { host, ... }:
    let
      info = hosts.mkHostInfo host;
    in
    {
      # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test
      systemd.services.${svc} = {
        unitConfig = {
          Requires = [ info.unit ];
          BindsTo = [ info.unit ];
          After = [ info.unit ];
        };

        serviceConfig = {
          NetworkNamespacePath = info.namespace;
          DevicePolicy = "closed";
          PrivateTmp = true;
          PrivateMounts = true;
          ProtectSystem = "strict";
          ProtectHome = "tmpfs";
          Restart = nixpkgs.lib.mkForce "always";
        };
      };
    });

  mkOptions = { name }: {
    enable = nixpkgs.lib.mkEnableOption name;
  };
in
{
  nixosModules.services = { ... }:
  {
    options.foxDen.services.trustedProxies = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = listOf str;
      default = [];
    };
  };

  make = (inputs@{ host, ... }: make (inputs.name or host) inputs);

  mkHttpOptions = (inputs@{ ... } : with nixpkgs.lib.types; nixpkgs.lib.mergeAttrs {
    hostPort = nixpkgs.lib.mkOption {
      type = str;
      default = "";
    };
    tls = nixpkgs.lib.mkEnableOption "TLS";
  } (mkOptions inputs));
  mkOptions = mkOptions;

  makeHTTPProxy = (inputs@{ config, svcConfig, pkgs, host, target, ... }:
    let
      caddyStorageRoot = "/var/lib/foxden/services/caddy/${host}";
      caddyConfigRoot = "/etc/caddy/sites/${host}";
      caddyUser = "foxden-caddy-${host}";

      hostCfg = hosts.mkHostConfig config host;
      hostPort = if svcConfig.hostPort != "" then svcConfig.hostPort else "${hostCfg.name}.${hostCfg.root}";
      url = (if svcConfig.tls then "" else "http://") + hostPort;

      serviceName = "host-${host}-ingress";
      svc = make serviceName inputs;
      caddyFilePath = "${caddyConfigRoot}/Caddyfile";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");

      trustedProxies = config.foxDen.services.trustedProxies;
      mkTrustedProxies = (prefix:
                          if (builtins.length trustedProxies) > 0
                            then (prefix + " " + (nixpkgs.lib.strings.concatStringsSep " " trustedProxies))
                            else "#${prefix} none");

      caddyFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" caddyFilePath;
    in
    (nixpkgs.lib.mkMerge [
      svc
      {
        environment.etc.${caddyFileEtc}.text = ''
          {
            storage file_system {
              root ${caddyStorageRoot}
            }
            servers {
              listener_wrappers {
                proxy_protocol {
                  timeout 5s
                  ${mkTrustedProxies "allow"}
                }
                tls
              }
              trusted_proxies_strict
              ${mkTrustedProxies "trusted_proxies static"}
            }
          }

          http:// {
            # Required dummy empty section
          }

          ${url} {
            reverse_proxy ${target}
          }
        '';

        environment.persistence."/nix/persist/foxden/services".directories = [
          { directory = caddyStorageRoot; user = caddyUser; group = caddyUser; mode = "u=rwx,g=,o="; }
        ];

        users.users.${caddyUser} = {
          isSystemUser = true;
          group = caddyUser;
        };
        users.groups.${caddyUser} = {};

        systemd.services.${serviceName} = {
          reloadTriggers = [ config.environment.etc.${caddyFileEtc}.text ];
          serviceConfig = {
            Environment = [
              "XDG_CONFIG_HOME=${caddyStorageRoot}"
            ];
            ExecStart = "${cmd} run --config ${eSA caddyFilePath}";
            ExecReload = "${cmd} reload --config ${eSA caddyFilePath}";
            User = caddyUser;
            Group = caddyUser;
            Restart = "always";
            ReadWritePaths = [caddyStorageRoot];
            ReadOnlyPaths = [caddyConfigRoot];
            AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          };
          wantedBy = ["multi-user.target"];
        };
      }
    ]));
}
