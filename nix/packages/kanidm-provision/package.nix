{ lib, pkgs, ... }:
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kanidm-provision";
  version = "1.3.1";

  src = pkgs.fetchFromGitHub {
    owner = "Doridian";
    repo = "kanidm-provision";
    rev = "139c2762e77e10cb2327d76f2f8d99e91e4cb07b";
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
