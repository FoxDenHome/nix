{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, lanzaboote, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations = {
      testvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/qemu.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };

      bengalfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/bengalfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
      islandfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/islandfox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
      icefox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/icefox.nix
          lanzaboote.nixosModules.lanzaboote
          ./server.nix
        ];
      };
    };
  };
}
