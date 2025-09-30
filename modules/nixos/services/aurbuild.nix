{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
in
{
  options.foxDen.services.aurbuild = foxDenLib.services.oci.mkOptions { svcName = "aurbuild"; name = "AUR Build Service"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.mkNamed "aurbuild" {
      inherit pkgs config svcConfig;
      image = "ghcr.io/doridian/aurbuild/aurbuild:latest";
      name = "aurbuild";
    }).config
    {
      
    }
  ]);
}
