{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, lanzaboote, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations = {
      testvm = nixpkgs.lib.nixosSystem {
        system.stateVersion = "25.05";

        modules = [
          nixos-hardware.nixosModules.qemu-guest
          ./machines/testvm.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };

      bengalfox = nixpkgs.lib.nixosSystem {
        system.stateVersion = "25.05";

        modules = [
          ./machines/bengalfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
      islandfox = nixpkgs.lib.nixosSystem {
        system.stateVersion = "25.05";

        modules = [
          ./machines/islandfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
      icefox = nixpkgs.lib.nixosSystem {
        system.stateVersion = "25.05";

        modules = [
          ./machines/icefox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
    };
  };
}
