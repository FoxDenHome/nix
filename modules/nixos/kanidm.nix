{ pkgs, config, ... } :
{
  security.wrappers."kanidm_ssh_authorizedkeys" = {
    source = "${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys";
    owner = "root";
    group = "root";
  };

  services.openssh = {
    authorizedKeysCommand = "/run/wrappers/bin/kanidm_ssh_authorizedkeys %u";
    authorizedKeysCommandUser = "nobody";
  };

  security.sudo.enable = false;

  security.polkit = {
    enable = true;
    adminIdentities = [ "unix-group:superadmins" "unix-group:wheel" ];
  };

  nix.settings.allowed-users = [ "@superadmins" ];

  services.kanidm = {
    enableClient = true;
    enablePam = true;

    package = pkgs.kanidm_1_7;

    clientSettings = {
      uri = "https://auth.foxden.network";
      verify_ca = true;
      verify_hostnames = true;
    };

    unixSettings = {
      pam_allowed_login_groups = [ "login-users" ];
      allow_local_account_override = [ "share" ];
      default_shell = "${pkgs.fish}/bin/fish";
      uid_attr_map = "name";
      gid_attr_map = "name";
      home_attr = "name";
      home_alias = "none";
    };
  };

  environment.persistence."/nix/persist/system".directories = [
    { directory = "/var/cache/kanidm-unixd"; user = "kanidm-unixd"; group = "kanidm-unixd"; mode = "u=rwx,g=,o="; }
  ];
}
