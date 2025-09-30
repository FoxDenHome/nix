{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
in
{
  options.foxDen.services.aurbuild.enable = lib.mkEnableOption "aurbuild";

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.mkNamed "aurbuild" {
      inherit pkgs config svcConfig;
      image = "ghcr.io/doridian/aurbuild/aurbuild:latest";
      name = "aurbuild";
    }).config
    {
      
    }
  ]);
}
