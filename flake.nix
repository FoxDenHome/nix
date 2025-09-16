{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations.bengalfox-vm = nixpkgs.lib.nixosSystem {
      modules = [
        nixos-hardware.qemu-guest
        ./server.nix
        ./machines/bengalfox-vm.nix
      ];
    };
  };
}
