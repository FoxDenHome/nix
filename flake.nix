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
      isValidModule = path: nixpkgs.lib.filesystem.pathIsRegularFile path && nixpkgs.lib.strings.hasSuffix ".nix" path;
      moduleFiles = nixpkgs.lib.filter isValidModule
                      (nixpkgs.lib.filesystem.listFilesRecursive ./modules/nixos);

      baseModules = [
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
      ] ++ moduleFiles;
    in
    {
      # Actual machines
      bengalfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/bengalfox.nix
        ] ++ baseModules;
      };
      islandfox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/islandfox.nix
        ] ++ baseModules;
      };
      icefox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./systems/x86_64-linux/icefox.nix
        ] ++ baseModules;
      };

      # Test machines
      testvm = nixpkgs.lib.nixosSystem {
        modules = [
          ({ ... }: {
            networking.hostName = "testvm";
            networking.hostId = "5445564d";
          })
          ./systems/x86_64-linux/testvm.nix
        ] ++ baseModules;
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
          ./systems/x86_64-linux/testvm.nix
        ] ++ baseModules;
      };
    };
  };
}
