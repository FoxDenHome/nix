{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };

  make = ({ name, ... }:
    let
      info = hosts.mkHostInfo name;
    in
    {
      oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test

      systemd.unitConfig = {
        Requires = [ info.unit ];
        BindsTo = [ info.unit ];
        After = [ info.unit ];
      };

      systemd.serviceConfig = {
        NetworkNamespacePath = info.namespace;
        DevicePolicy = "closed";
        PrivateTmp = true;
        PrivateMounts = true;
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        ReadOnlyPaths = ["/"];
        Restart = "always";
      };
    });
in
{
  make = make;

  makeHTTPProxy = (inputs@{ name, url, target, ... }:
    let
      cfg = make inputs;
      caddyfile = "/etc/caddy/sites/${name}/Caddyfile";
      cmd = "${nixpkgs.pkgs.caddy}/bin/caddy";
    in
    {
      environment.etc.${nixpkgs.lib.strings.removePrefix "/etc/" caddyfile}.text = ''
        ${url} {
          reverse_proxy ${target}
        }
      '';
      systemd.unitConfig = cfg.systemd.unitConfig;
      systemd.serviceConfig = nixpkgs.lib.mkMerge [
        cfg.systemd.serviceConfig
        {
          ExecStart = "${cmd} run --config ${caddyfile}";
          ExecReload = "${cmd} reload --config ${caddyfile}";
          Restart = "always";
        }
      ];
    });
}
