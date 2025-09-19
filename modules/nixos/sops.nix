{ lib, config, ... } :
let
  sharedSopsFile = ../../secrets/shared.yaml;
in
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config = lib.mkIf config.foxDen.sops.available {
    sops.secrets.rootPasswordHash = {
      neededForUsers = true;
    };
    
    users.mutableUsers = false;

    users.users.root.hashedPasswordFile = lib.mkIf config.foxDen.sops.available config.sops.secrets.rootPasswordHash.path;

    nix.extraOptions = lib.mkIf config.foxDen.sops.available ''
      !include ${config.sops.secrets.nixConfig.path}
    '';
    sops.secrets.nixConfig = lib.mkIf config.foxDen.sops.available {
      sopsFile = sharedSopsFile;
    };
  };
}
