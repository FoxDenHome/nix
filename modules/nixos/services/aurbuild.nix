{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
  mirrorCfg = config.foxDen.services.mirror;
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
      virtualisation.oci-containers.containers."aurbuild" = {
        volumes = config.lib.foxDen.sops.mkIfAvailable [
          "${config.sops.secrets.aurbuildGpgPin.path}:/gpg/pin:ro"
          "aurbuild_cache:/aur/cache"
          "${mirrorCfg.dataDir}/foxdenaur/${nixpkgs.hostPlatform}:/aur/repo"
        ];
      };
    }
  ]);
}
