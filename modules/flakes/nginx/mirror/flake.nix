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
          default = pkgs.buildNpmPackage {
            pname = "js";
            version = "1.0.0";
            src = ./.;
            npmDepsHash = "sha256-m1SqAS7GCsBGBt2tG/AySWHWk1tHc1ZJvB/yleV6P24=";
          };
        };
      });
}