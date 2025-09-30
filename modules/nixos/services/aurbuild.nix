{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
  mirrorCfg = config.foxDen.services.mirror;
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
          "/etc/foxden/aurbuild/packages.txt:/aur/packages.txt:ro"
          (config.lib.foxDen.sops.mkIfAvailable "${config.sops.secrets.aurbuildGpgPin.path}:/gpg/pin:ro")
          "aurbuild_cache_${nixpkgs.hostPlatform}:/aur/cache"
          "${mirrorCfg.dataDir}/foxdenaur/${nixpkgs.hostPlatform}:/aur/repo"
        ];
        environment = {
          "GPG_KEY_ID" = "45B097915F67C9D68C19E5747B0F7660EAEC8D49";
        };
      };
    }).config
    {
      environment.etc."foxden/aurbuild/packages.txt".text = lib.concatStringsSep "\n" (svcConfig.packages ++ [ "" ]);

      services.pcscd.enable = true;
      programs.gpg.scdaemonSettings = {
        disable-ccid = true;
        pcsc-shared = true;
      };
      sops.secrets.aurbuildGpgPin = config.lib.foxDen.sops.mkIfAvailable {};
    }
  ];
}
