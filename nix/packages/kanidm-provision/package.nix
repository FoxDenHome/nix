{ lib, pkgs, ... }:
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kanidm-provision";
  version = "1.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "Doridian";
    repo = "kanidm-provision";
    rev = "6862c31fc69cd808dd3568fda9f00a9396ddcc62";
    hash = "sha256-ZLgNdh+Els7beJbdzjusXehfgOHSkhGkPAcBFhyQOlE=";
  };

  cargoHash = "sha256-dPTrIc/hTbMlFDXYMk/dTjqaNECazldfW43egDOwyLM=";

  nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
  versionCheckProgramArg = "--version";
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
