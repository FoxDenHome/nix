{
  description = "FoxDen NixOS config";

  inputs = {
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { lanzaboote, impermanence, nixpkgs, ... }:
  {
    nixosConfigurations =
    let
      is_valid_module = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;
      module_files = nixpkgs.lib.filter is_valid_module
                      (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos);
    in
    {
      # Actual machines
      bengalfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/bengalfox.nix
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
        ] ++ module_files;
      };
      islandfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/islandfox.nix
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
        ] ++ module_files;
      };
      icefox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/icefox.nix
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
        ] ++ module_files;
      };

      # Test machines
      testvm = nixpkgs.lib.nixosSystem {
        modules = [
          ({ ... }: {
            networking.hostName = "testvm";
            networking.hostId = "5445564d";
          })
          impermanence.nixosModules.impermanence
          ./systems/x86_64-linux/testvm.nix
          lanzaboote.nixosModules.lanzaboote
        ] ++ module_files;
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
        ] ++ module_files;
      };
    };
  };
}
