{ config, lib, pkgs, ... } :
let
  # TODO: Use a lanzaboote post script for this, once they exist
  syncBootScript = ''
    if [ -d /boot2/EFI ]; then
      rsync -av --delete /boot/ /boot2/
    else
      echo 'No /boot2/EFI, skipping'
    fi
  '';

  updateScript = pkgs.writeShellScript "update-nixos.sh" ''
    set -xeuo pipefail
    nix flake update --flake 'github:FoxDenHome/core?dir=nix' || true
    nixos-rebuild switch --flake "github:FoxDenHome/core?dir=nix#$(hostname)"
    ${syncBootScript}
  '';

  pruneScript = pkgs.writeShellScript "prune-nixos.sh" ''
    set -xeuo pipefail
    nix-collect-garbage --delete-old
    /run/current-system/bin/switch-to-configuration boot
    ${syncBootScript}
  '';

  cryptenrollScript = pkgs.writeShellScript "cryptenroll.sh" (''
      #!/usr/bin/env bash
      set -xeuo pipefail
      enroll_disk() {
        systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs '0:sha256+7:sha256+14:sha256' "$1"
      }
    ''
    + (builtins.concatStringsSep "\n"
        (map (dev: "enroll_disk ${dev.device}")
          (lib.attrsets.attrValues config.boot.initrd.luks.devices))) + "\n");
in
{
  environment.etc."foxden/nixos/update.sh".source = updateScript;
  environment.etc."foxden/nixos/prune.sh".source = pruneScript;
  environment.etc."foxden/cryptenroll.sh".source = cryptenrollScript;
}
