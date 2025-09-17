{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { lanzaboote, impermanence, nixpkgs, ... }:
  {
    nixosConfigurations = {
      testvm = nixpkgs.lib.nixosSystem {
        networking.hostName = "testvm";
        networking.hostId = "5445564d";

        modules = [
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/testvm.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
        ];
      };
      testvm-zfs = nixpkgs.lib.nixosSystem {
        networking.hostName = "testvm-zfs";
        networking.hostId = "545a4653";

        fileSystems."/mnt/zhdd" =
          { device = "zhdd/ROOT";
            fsType = "zfs";
          };

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
        networking.hostName = "bengalfox";
        networking.hostId = "42474c46";
  
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
        networking.hostName = "islandfox";
        networking.hostId = "494c4446";

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
        networking.hostName = "icefox";
        networking.hostId = "49434546";

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
