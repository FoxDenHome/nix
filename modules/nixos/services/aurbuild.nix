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

        environment = {
          "GPG_KEY_ID" = "45B097915F67C9D68C19E5747B0F7660EAEC8D49";
        };
      };
    }
  ]);
}
