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

    caddyStorageRoot = "/var/lib/foxden/services/caddy";
in
{
  nixosModules.services = { ... }:
  {
    environment.persistence."/nix/persist/foxden/services".directories = [
      { directory = caddyStorageRoot; user = "caddy"; group = "caddy"; mode = "u=rwx,g=,o="; }
    ];

    users.users.caddy = {};
  };

  make = (inputs@{ host, ... }: make host inputs);

  makeHTTPProxy = (inputs@{ config, pkgs, host, tls, target, ... }:
    let
      hostCfg = hosts.mkHostConfig config host;
      url = (if tls then "" else "http://") + "${hostCfg.name}.${hostCfg.root}";

      serviceName = "${host}-ingress";
      svc = make serviceName inputs;
      caddyfile = "/etc/caddy/sites/${host}/Caddyfile";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");

      storageDir = "${caddyStorageRoot}/${host}";
    in
    {
      config = nixpkgs.lib.mkMerge [
        svc.config
        {
          environment.etc.${nixpkgs.lib.strings.removePrefix "/etc/" caddyfile}.text = ''
            {
              storage file_system {
                root ${storageDir}
              }
            }
            ${url} {
              reverse_proxy ${target}
            }
          '';

          systemd.services.${serviceName} = {
            serviceConfig = {
              Environment = [
                "XDG_DATA_HOME=${storageDir}"
              ];
              ExecStart = "${cmd} run --config ${eSA caddyfile}";
              ExecReload = "${cmd} reload --config ${eSA caddyfile}";
              User = "caddy";
              Group = "caddy";
              Restart = "always";
              ReadWritePaths = [storageDir];
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ];
    });
}
