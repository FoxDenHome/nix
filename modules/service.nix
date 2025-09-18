{ nixpkgs, ... }:
let
  dns = import ./dns.nix { inherit nixpkgs; };
in
{
  mkHostService = (args@{ name, ... }: ({ config, ... }: {
    options.foxDen.${name}.host = (dns.mkHostOption (nixpkgs.lib.mergeAttrs {
      default = null;
    } args.opts or {}));

    config.dns.hosts = [ config.foxDen.${name}.host ];
  }));
}
