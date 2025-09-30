{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
in
{
  options.foxDen.services.aurbuild.enable = foxDenLib.oci.mkOptions { svcName = "aurbuild"; name = "AUR Build Service"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.oci.mkNamed "aurbuild" {
      inherit pkgs config svcConfig;
      image = "ghcr.io/doridian/aurbuild/aurbuild:latest";
      name = "aurbuild";
    }).config
    {
      
    }
  ]);
}
