{ config, lib, ... } :
{
  environment.etc."nix/update.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -xeuo pipefail
      nix flake update --flake 'github:FoxDenHome/core?dir=nix' || true
      nixos-rebuild switch --flake "github:FoxDenHome/core?dir=nix#$(hostname)"
      /etc/nix/sync-boot.sh
    '';
    mode = "0755";
  };

  environment.etc."nix/cleanup.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -xeuo pipefail
      nix-collect-garbage --delete-old
      /run/current-system/bin/switch-to-configuration boot
      /etc/nix/sync-boot.sh
    '';
    mode = "0755";
  };

  # TODO: Use a lanzaboote post script for this, once they exist
  environment.etc."nix/sync-boot.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -xeuo pipefail
      if [ -d /boot2 ]; then
        rsync -av --delete /boot/ /boot2/
      else
        echo 'No /boot2, skipping'
      fi
    '';
    mode = "0755";
  };

  environment.etc."nix/cryptenroll.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -xeuo pipefail
      enroll_disk() {
        systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs '0:sha256+7:sha256+14:sha256' "$1"
      }
    ''
    + (lib.concatMapStringsSep "\n"
        (map (dev: "enroll_disk ${dev.device}")
          (lib.attrsets.attrValues config.boot.initrd.luks.devices)));
    mode = "0755";
  };
}
