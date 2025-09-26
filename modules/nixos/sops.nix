{ lib, config, ... } :
let
  sharedSopsFile = ../../secrets/shared.yaml;

  mkIfAvailable = lib.mkIf config.foxDen.sops.available;
in
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config = lib.mkMerge [
    {
      lib.foxDen.sops = {
        inherit mkIfAvailable;
      };
    }
    (mkIfAvailable {
      sops.secrets.rootPasswordHash = {
        neededForUsers = true;
      };

      users.mutableUsers = false;

      users.users.root.hashedPasswordFile = config.sops.secrets.rootPasswordHash.path;

      nix.extraOptions = ''
        !include ${config.sops.secrets.nixConfig.path}
      '';
      sops.secrets.nixConfig = {
        sopsFile = sharedSopsFile;
      };
    })
  ];
}
