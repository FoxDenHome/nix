{ ... } :
{
  environment.etc."nix/update.sh" = {
    text = ''
      #!/usr/bin/env sh
      set -x
      nix flake update --flake 'github:FoxDenHome/nix'
      exec nixos-rebuild switch --flake "github:FoxDenHome/nix#$(hostname)"
    '';
    mode = "0755";
  };

  environment.etc."nix/cleanup.sh" = {
    text = ''
      #!/usr/bin/env sh
      set -x
      nix-collect-garbage --delete-old
      /run/current-system/bin/switch-to-configuration boot
    '';
    mode = "0755";
  };
}
