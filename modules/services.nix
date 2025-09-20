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
          Restart = "always";
        };
      };
    });
in
{
  make = (inputs@{ host, ... }: make host inputs);

  makeHTTPProxy = (inputs@{ config, pkgs, host, tls, target, ... }:
    let
      hostCfg = config.foxDen.hosts.${host};
      url = (if tls then "" else "http://") + "${hostCfg.name}.${hostCfg.root}";

      serviceName = "${host}-http";
      svc = make serviceName inputs;
      caddyfile = "/etc/caddy/sites/${host}/Caddyfile";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");
    in
    {
      config = nixpkgs.lib.mkMerge [
        svc.config
        {
          environment.etc.${nixpkgs.lib.strings.removePrefix "/etc/" caddyfile}.text = ''
            ${url} {
              reverse_proxy ${target}
            }
          '';

          systemd.services.${serviceName} = {
            serviceConfig = {
              ExecStart = "${cmd} run --config ${eSA caddyfile}";
              ExecReload = "${cmd} reload --config ${eSA caddyfile}";
              Restart = "always";
            };
          };
        }
      ];
    });
}
