{ nixpkgs, ... } :
{
  driverOptsType = with nixpkgs.lib.types; submodule {};
  build = { ... }: { config.systemd = {}; };
  hooks = { ... }: { start = [ ]; stop = [ ]; };
}
