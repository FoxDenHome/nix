{ lib, config, ... } :
let
  sharedSopsFile = ../../secrets/shared.yaml;

  mkIfAvailable = lib.mkIf config.foxDen.sops.available;
  mkGithubTokenPath = mkIfAvailable config.sops.secrets.githubTokenEnv.path;
in
{
  options.foxDen.sops.available = lib.mkEnableOption "Enable sops-nix usage";

  config = lib.mkMerge [
    {
      lib.foxDen.sops = {
        inherit mkIfAvailable mkGithubTokenPath;
      };
    }
    (mkIfAvailable {
      sops.secrets.rootPasswordHash = {
        neededForUsers = true;
      };

      sops.secrets.githubTokenEnv = {
        sopsFile = sharedSopsFile;
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
