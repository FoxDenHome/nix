{ lib, pkgs, ... }:
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kanidm-provision";
  version = "0.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "Doridian";
    repo = "kanidm-provision";
    rev = "139c2762e77e10cb2327d76f2f8d99e91e4cb07b";
    hash = "sha256-m3bF4wFPVRc2E+E/pZc3js9T4rYbTejo/FFpysytWKw=";
  };

  cargoHash = "sha256-dPTrIc/hTbMlFDXYMk/dTjqaNECazldfW43egDOwyLM=";

  doInstallCheck = true;

  passthru = {
    updateScript = pkgs.nix-update-script { };
  };

  meta = {
    description = "Small utility to help with kanidm provisioning";
    homepage = "https://github.com/Doridian/kanidm-provision";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "kanidm-provision";
  };
})
