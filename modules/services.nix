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
      config.systemd.services.${svc} = {
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
          ReadOnlyPaths = ["/"];
          Restart = nixpkgs.lib.mkForce "always";
        };
      };
    });
in
{
  nixosModules.services = { ... }:
  {

  };

  make = (inputs@{ host, ... }: make host inputs);

  makeHTTPProxy = (inputs@{ config, pkgs, host, tls, target, ... }:
    let
      caddyStorageRoot = "/var/lib/foxden/services/caddy/${host}";
      caddyUser = "foxden-caddy-${host}";

      hostCfg = hosts.mkHostConfig config host;
      url = (if tls then "" else "http://") + "${hostCfg.name}.${hostCfg.root}";

      serviceName = "${host}-ingress";
      svc = make serviceName inputs;
      caddyfile = "/etc/caddy/sites/${host}/Caddyfile";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");
    in
    {
      config = nixpkgs.lib.mkMerge [
        svc.config
        {
          environment.etc.${nixpkgs.lib.strings.removePrefix "/etc/" caddyfile}.text = ''
            {
              storage file_system {
                root ${caddyStorageRoot}
              }
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
            serviceConfig = {
              Environment = [
                "XDG_DATA_HOME=${caddyStorageRoot}"
              ];
              ExecStart = "${cmd} run --config ${eSA caddyfile}";
              ExecReload = "${cmd} reload --config ${eSA caddyfile}";
              User = caddyUser;
              Group = caddyUser;
              Restart = "always";
              ReadWritePaths = [caddyStorageRoot];
              AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ];
    });
}
