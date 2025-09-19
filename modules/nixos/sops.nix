{ lib, config, ... } :
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config.sops.secrets.rootPasswordHash = lib.mkIf config.foxDen.sops.available {
    neededForUsers = true;
  };

  config.users.users.root.hashedPasswordFile = lib.mkIf config.foxDen.sops.available config.sops.secrets.rootPasswordHash.path;
  config.users.users.root.hashedPassword = lib.mkIf (!config.foxDen.sops.available) "$y$j9T$IiDZbOYNQ3/pi9/K2QdUm0$GizBNTJUmYCp3OTixpF6kkmFy6XMwszNIxmbOcaEtyA";
}
