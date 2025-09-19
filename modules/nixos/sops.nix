{ lib, config, ... } :
let
  sharedSopsFile = ../../secrets/shared.yaml;
in
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config.sops.secrets.rootPasswordHash = lib.mkIf config.foxDen.sops.available {
    neededForUsers = true;
  };

  config.users.users.root.hashedPasswordFile = lib.mkIf config.foxDen.sops.available config.sops.secrets.rootPasswordHash.path;
  config.users.mutableUsers = ! config.foxDen.sops.available;

  config.nix.extraOptions = lib.mkIf config.foxDen.sops.available ''
    !include ${config.sops.secrets.nixConfig.path}
  '';
  config.sops.secrets.nixConfig = lib.mkIf config.foxDen.sops.available {
    sopsFile = sharedSopsFile;
  };
}
