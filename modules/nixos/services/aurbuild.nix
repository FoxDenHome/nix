{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
  mirrorCfg = config.foxDen.services.mirror;

  packagesTxt = pkgs.writers.writeText "packages.txt" (lib.concatStringsSep "\n" (svcConfig.packages ++ [ "" ]));
in
{
  options.foxDen.services.aurbuild = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Which packages to build";
    };
  } // (foxDenLib.services.oci.mkOptions { svcName = "aurbuild"; name = "AUR build service"; });

  config = lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "aurbuild";
      oci = {
        image = "ghcr.io/doridian/aurbuild/aurbuild:latest";
        volumes = [
          "${packagesTxt}:/aur/packages.txt:ro"
          (config.lib.foxDen.sops.mkIfAvailable "${config.sops.secrets.aurbuildGpgPin.path}:/gpg/pin:ro")
          "aurbuild_cache_${config.nixpkgs.hostPlatform}:/aur/cache"
          "${mirrorCfg.dataDir}/foxdenaur/${config.nixpkgs.hostPlatform}:/aur/repo"
        ];
        environment = {
          "GPG_KEY_ID" = "45B097915F67C9D68C19E5747B0F7660EAEC8D49";
        };
      };
    }).config
    {
      services.pcscd.enable = true;
      # programs.gpg.scdaemonSettings = {
      #   disable-ccid = true;
      #   pcsc-shared = true;
      # };
      sops.secrets.aurbuildGpgPin = config.lib.foxDen.sops.mkIfAvailable {};
    }
  ];
}
