{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: let
    packageJson = nixpkgs.lib.trivial.importJSON ./package.json;
  in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        package =  (pkgs.stdenv.mkDerivation {
          name = packageJson.name;
          version = packageJson.version;
          srcs = [
            (pkgs.fetchurl {
              url = "https://github.com/nginx/njs-acme/releases/download/v1.0.0/acme.js";
              hash = "sha256-Gu+3Ca/C7YHAf7xfarZYeC/pnohWnuho4l06bx5TVcs=";
            })
            (pkgs.buildNpmPackage {
              pname = "${packageJson.name}-js";
              version = packageJson.version;
              src = ./.;
              npmDeps = pkgs.importNpmLock { npmRoot = ./.; };
              npmConfigHook = pkgs.importNpmLock.npmConfigHook;
            })
          ];

          unpackPhase = ''
            for srcFile in $srcs; do
              case "$(stripHash "$srcFile")" in
                acme.js)
                  cp "$srcFile" acme.js
                  ;;
                **)
                  cp -r "$srcFile/"* .
                  ;;
              esac
            done
          '';

          installPhase = ''
            mkdir -p $out
            ls -la ./lib/node_modules
            cp -r 'lib/node_modules/${packageJson.name}/'* $out/
            chmod 755 $out/lib
            cp acme.js $out/lib/acme.js
            chmod 555 $out/lib
          '';
        });
      in
      {
        packages.default = package;
        packages.${packageJson.name} = package;
      });
}
