{ lib, config, ... } :
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config.sops.secrets.rootPasswordHash = lib.mkIf config.foxDen.sops.available {
    neededForUsers = true;
  };

  config.users.users.root.hashedPasswordFile = lib.mkIf config.foxDen.sops.available config.sops.secrets.rootPasswordHash.path;
}
