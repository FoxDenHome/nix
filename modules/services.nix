{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };

  mkNamed = (svc: { host, ... }:
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
in
{
  mkOptions = { name }: {
    enable = nixpkgs.lib.mkEnableOption name;
  };

  make = (inputs@{ host, ... }: mkNamed (inputs.name or host) inputs);
  mkNamed = mkNamed;
}
