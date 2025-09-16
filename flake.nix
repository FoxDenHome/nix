{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs@{ self, lanzaboote, impermanence, nixpkgs, ... }:
  {
    nixosConfigurations = {
      testvm = nixpkgs.lib.nixosSystem {
        modules = [
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/testvm.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
          ./modules/nixos/zfs.nix
        ];
      };

      bengalfox = nixpkgs.lib.nixosSystem {
        modules = [
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/bengalfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
          ./modules/nixos/zfs.nix
        ];
      };
      islandfox = nixpkgs.lib.nixosSystem {
        modules = [
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/islandfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
        ];
      };
      icefox = nixpkgs.lib.nixosSystem {
        modules = [
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/icefox.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
          ./modules/nixos/zfs.nix
        ];
      };
    };
  };
}
