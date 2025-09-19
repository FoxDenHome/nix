{ pkgs, lib, config, ... } :
{
  options.foxDen.kanidm.login = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable kanidm login";
  };

  config = lib.mkIf config.foxDen.kanidm.enable {
    security.wrappers."kanidm_ssh_authorizedkeys" = {
      source = "${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys";
      owner = "root";
      group = "root";
    };

    services.openssh = {
      authorizedKeysCommand = "/run/wrappers/bin/kanidm_ssh_authorizedkeys %u";
      authorizedKeysCommandUser = "nobody";
    };

    security.polkit.adminIdentities = [ "unix-group:superadmins" "unix-group:wheel" ];

    nix.settings.allowed-users = [ "@superadmins" ];

    services.kanidm = {
      enablePam = true;

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
  };
}
