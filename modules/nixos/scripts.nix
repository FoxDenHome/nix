{ ... } :
{
  environment.etc."nix/update.sh" = {
    text = ''
      #!/usr/bin/env sh
      set -x
      nix flake update --flake 'github:FoxDenHome/nix'
      nixos-rebuild switch --flake 'github:FoxDenHome/nix#testvm-fde'
    '';
    mode = "u=rwx,g=rx,o=rx";
  };

  environment.etc."nix/cleanup.sh" = {
    text = ''
      #!/usr/bin/env sh
      set -x
      nix-collect-garbage --delete-old
      /run/current-system/bin/switch-to-configuration boot
    '';
    mode = "u=rwx,g=rx,o=rx";
  };
}
