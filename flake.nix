{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = inputs@{ self, lanzaboote, nixpkgs, ... }:
  {
    nixosConfigurations = {
      testvm = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/testvm.nix
          lanzaboote.nixosModules.lanzaboote
          ./shared/base.nix
          ./shared/boot.nix
          ./shared/kanidm.nix
        ];
      };

      bengalfox = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/bengalfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./shared/base.nix
          ./shared/boot.nix
          ./shared/kanidm.nix
        ];
      };
      islandfox = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/islandfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./shared/base.nix
          ./shared/boot.nix
          ./shared/kanidm.nix
        ];
      };
      icefox = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/icefox.nix
          lanzaboote.nixosModules.lanzaboote
          ./shared/base.nix
          ./shared/boot.nix
          ./shared/kanidm.nix
        ];
      };
    };
  };
}
