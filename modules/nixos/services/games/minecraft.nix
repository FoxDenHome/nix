{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.minecraft;

  defaultDataDir = "/var/lib/minecraft";
  ifDefaultData = lib.mkIf (svcConfig.dataDir == defaultDataDir);

  serverPackage = (pkgs.stdenv.mkDerivation {
    name = "minecraft-server-package";
    version = "1.0.0";
    srcs = [
      (pkgs.fetchzip {
        url = "https://mediafilez.forgecdn.net/files/7046/196/All_of_Create_6.0_v2.0_serverpack.zip";
        name = "server";
        stripRoot = false;
        hash = "sha256-G7J40m6Jjqc4Oi0q0RMIup/8AsNbY+dy1/0BSmeR4Nw=";
      })
      (pkgs.fetchurl {
        url = "https://cdn.modrinth.com/data/E1XS8bXN/versions/rLfqDKHu/PlayerCollars-1.2.6%2B1.20.1-forge.jar";
        hash = "sha256-kEYZzR+tWaISRCkvZ0I1nHHXUabZxMdchs7YxX+HBqA=";
      })
      ./minecraft-run.sh
      ./minecraft-install.sh
      ./server-icon.png
    ];

    unpackPhase = ''
      mkdir -p server/mods
      for srcFile in $srcs; do
        echo "Copying from $srcFile"
        if [ -d $srcFile ]; then
          rm -rf server-tmp && mkdir -p server-tmp
          cp -r $srcFile/* server-tmp
          chmod 600 server-tmp/server-icon.png server-tmp/variables.txt server-tmp/server.properties server-tmp/minecraft-*.sh server-tmp/nix-version.txt || true
          rm -fv server-tmp/server-icon.png server-tmp/variables.txt server-tmp/server.properties server-tmp/minecraft-*.sh server-tmp/nix-version.txt
          cp -r server-tmp/* server/
        else
          if [[ $srcFile == *.jar ]]; then
            cp -r $srcFile server/mods/$(stripHash $srcFile)
          else
            cp -r $srcFile server/$(stripHash $srcFile)
          fi
        fi
      done
    '';

    installPhase = ''
      mkdir -p $out
      cp -r ./server $out/
      chmod 500 $out/server/*.sh
    '';
  });
in
{
  options.foxDen.services.minecraft = with lib.types; {
    jrePackage = lib.mkOption {
      type = package;
      description = "JRE package to use for running Minecraft server";
    };
    dataDir = lib.mkOption {
      type = path;
      default = defaultDataDir;
      description = "Directory to store Minecraft data";
    };
  } // (services.http.mkOptions { svcName = "minecraft"; name = "Minecraft server"; });

  # TODO: Make modpack a package and actually build it and only take the world

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      inherit svcConfig pkgs config;
      name = "minecraft";
    }).config
    {
      users.users.minecraft = {
        isSystemUser = true;
        group = "minecraft";
      };
      users.groups.minecraft = {};

      environment.systemPackages = [ pkgs.unzip ];

      systemd.services.minecraft = {
        confinement.packages = [
          svcConfig.jrePackage
          pkgs.coreutils
          pkgs.findutils
          pkgs.bash
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
          pkgs.wget
          pkgs.curl
          pkgs.unzip
        ];
        path = [
          svcConfig.jrePackage
          pkgs.coreutils
          pkgs.findutils
          pkgs.bash
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
          pkgs.wget
          pkgs.curl
          pkgs.unzip
        ];

        serviceConfig = {
          User = "minecraft";
          Group = "minecraft";

          Environment = [
            "SERVER_DIR=${svcConfig.dataDir}"
          ];

          BindPaths = [
            svcConfig.dataDir
          ];
          BindReadOnlyPaths = [
            "${serverPackage}/server:/server"
            "/usr/bin/env"
          ];
          WorkingDirectory = svcConfig.dataDir;

          ExecStartPre = [ "${serverPackage}/server/minecraft-install.sh" ];
          ExecStart = [ "${svcConfig.dataDir}/minecraft-run.sh" ];

          StateDirectory = ifDefaultData "minecraft";
        };

        wantedBy = [ "multi-user.target" ];
      };

      environment.persistence."/nix/persist/minecraft" = ifDefaultData {
        hideMounts = true;
        directories = [
          { directory = defaultDataDir; user = "minecraft"; group = "minecraft"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
