{ foxDenLib, pkgs, lib, config, ... }:
let
  svcConfig = config.foxDen.services.aurbuild;
  mirrorCfg = config.foxDen.services.mirror;

  packagesTxt = pkgs.writers.writeText "packages.txt" (lib.concatStringsSep "\n" (svcConfig.packages ++ [ "" ]));

  builderArch = "x86_64";
in
{
  options.foxDen.services.aurbuild = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Which packages to build";
    };
    makepkgConf = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional makepkg.conf";
    };
  } // (foxDenLib.services.oci.mkOptions { svcName = "aurbuild"; name = "AUR build service"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (foxDenLib.services.oci.make {
      inherit pkgs config svcConfig;
      name = "aurbuild";
      oci = {
        image = "ghcr.io/doridian/aurbuild/aurbuild:latest";
        volumes = [
          "${packagesTxt}:/aur/packages.txt:ro"
          "/etc/passwd:/etc/passwd:ro"
          "/etc/group:/etc/group:ro"
          "/run/pcscd:/run/pcscd:ro"
          (config.lib.foxDen.sops.mkIfAvailable "${config.sops.secrets."aurbuild-gpg-passphrase".path}:/gpg/passphrase:ro")
          "aurbuild_cache_${builderArch}:/aur/cache"
          "${mirrorCfg.dataDir}/foxdenaur/${builderArch}:/aur/repo"
        ] ++ (if svcConfig.makepkgConf != "" then [
          (pkgs.writeText "makepkg.conf" svcConfig.makepkgConf) + ":/etc/makepkg.conf:ro"
        ] else []);
        extraOptions = [
          "--mount=type=tmpfs,tmpfs-size=128M,destination=/aur/tmp"
        ];
        environment = {
          "GPG_KEY_ID" = "45B097915F67C9D68C19E5747B0F7660EAEC8D49";
          "PUSER" = "aurbuild";
          "PGROUP" = "aurbuild";
        };
      };
      systemd = {
        serviceConfig = {
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${mirrorCfg.dataDir}/foxdenaur/${builderArch}"
            "${pkgs.coreutils}/bin/chown aurbuild:aurbuild ${mirrorCfg.dataDir}/foxdenaur/${builderArch}"
          ];
        };
      };
    }).config
    {
      services.pcscd.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if ((
                action.id == "org.debian.pcsc-lite.access_card" ||
                action.id == "org.debian.pcsc-lite.access_pcsc"
                ) && subject.user == "aurbuild") {
                    return polkit.Result.YES;
            }
        });
      '';
      # Home-Manager
      # programs.gpg.scdaemonSettings = {
      #   disable-ccid = true;
      #   pcsc-shared = true;
      # };
      sops.secrets."aurbuild-gpg-passphrase" = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "aurbuild";
        group = "aurbuild";
      };

      users.users.aurbuild = {
        isSystemUser = true;
        group = "aurbuild";
        home = "/home/aur"; # This is for inside the container
      };
      users.groups.aurbuild = {};
    }
  ]);
}
