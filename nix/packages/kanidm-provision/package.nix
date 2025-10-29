{ lib, pkgs, ... }:
pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kanidm-provision";
  version = "1.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "Doridian";
    repo = "kanidm-provision";
    rev = "5c642b0c4fe214147c4907b04979db30a0ea311b";
    hash = "sha256-Qlep1Cv8kQQoKBLYoGvO0TxT39Jmc1T++mCoMy33mA0=";
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
