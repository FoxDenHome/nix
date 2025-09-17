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

        modules = [
          ({ ... }: {
            networking.hostName = "testvm";
            networking.hostId = "5445564d";
          })
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/testvm.nix
          lanzaboote.nixosModules.lanzaboote
          ./modules/nixos/base.nix
          ./modules/nixos/boot.nix
          ./modules/nixos/kanidm.nix
        ];
      };
      testvm-zfs = nixpkgs.lib.nixosSystem {

        modules = [
          ({ ... }: {
            networking.hostName = "testvm-zfs";
            networking.hostId = "545a4653";

            fileSystems."/mnt/zhdd" =
              { device = "zhdd/ROOT";
                fsType = "zfs";
              };
          })
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
          ({ ... }: {
            networking.hostName = "bengalfox";
            networking.hostId = "42474c46";
          })
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
          ({ ... }: {
            networking.hostName = "islandfox";
            networking.hostId = "494c4446";
          })
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
          ({ ... }: {
            networking.hostName = "icefox";
            networking.hostId = "49434546";
          })
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
