{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          default = (pkgs.stdenv.mkDerivation {
                name = "acme.js";
                srcs = [
                  (pkgs.fetchurl {
                    url = "https://github.com/nginx/njs-acme/releases/download/v1.0.0/acme.js";
                    hash = "sha256-Gu+3Ca/C7YHAf7xfarZYeC/pnohWnuho4l06bx5TVcs=";
                  })
                  (pkgs.buildNpmPackage {
                    pname = "mirrorweb";
                    version = "1.0.0";
                    src = ./.;
                    npmDepsHash = "sha256-yxrgmvzT498a7VoWzaJHcHzYiQJAaqDE1UwmrK2xba8=";
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
                  cp -r lib/node_modules/mirrorweb/* $out/
                  cp acme.js $out/lib/acme.js
                '';
              });
        };
      });
}