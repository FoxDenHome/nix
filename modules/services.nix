{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };
in
{
  mkHostService = (args@{ name, ... }:
    {
      module = ({ config, ... }: {
        options.foxDen.${name}.host = (hosts.mkOption (nixpkgs.lib.mergeAttrs {
          default = null;
        } args.opts or {}));

        config.foxDen.hosts = [ config.foxDen.${name}.host ];
      });
      enabled = ({ config, ... }: config.foxDen.${name}.host != null);
    });
}
