{ foxDenLib, backupmgr, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = "root";
    group = "root";
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.backupmgr;

  backupmgrPkg = backupmgr.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.backupmgr.enable = lib.mkEnabledOption "backupmgr";
  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.restic
        backupmgrPkg
      ];

      sops.secrets.backupmgr = config.lib.foxDen.sops.mkIfAvailable {};

      environment.etc."backupmgr/config.json".source = config.lib.foxDen.sops.mkIfAvailable config.sops.secrets.backupmgr.path;
    }
  ]);
}
