{ ... } :
{
  environment.etc."nix/update.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -xeuo pipefail
      nix flake update --flake 'github:FoxDenHome/nix' || true
      nixos-rebuild switch --flake "github:FoxDenHome/nix#$(hostname)"
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
}
