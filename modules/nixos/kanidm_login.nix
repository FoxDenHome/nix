{ pkgs, lib, config, ... } :
{
  options.foxDen.kanidm.login = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable kanidm login";
  };

  config = lib.mkIf config.foxDen.kanidm.login {
    security.wrappers."kanidm_ssh_authorizedkeys" = {
      source = "${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys";
      owner = "root";
      group = "root";
    };

    environment.shells = [
      "/usr/bin/fish"
      "/usr/bin/zsh"
      "/usr/bin/bash"
      "/bin/fish"
      "/bin/zsh"
      "/bin/bash"
    ];

    # Otherwise, selected shells just won't work...
    systemd.tmpfiles.rules = [
      "L /usr/bin/bash - - - - ${pkgs.bash}/bin/bash"
      "L /usr/bin/fish - - - - ${pkgs.fish}/bin/fish"
      "L /usr/bin/zsh - - - - ${pkgs.zsh}/bin/zsh"
      "L /bin/bash - - - - ${pkgs.bash}/bin/bash"
      "L /bin/fish - - - - ${pkgs.fish}/bin/fish"
      "L /bin/zsh - - - - ${pkgs.zsh}/bin/zsh"
    ];

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

    systemd.services.kanidm-unixd = {
      serviceConfig = {
        BindReadOnlyPaths = [ "-/bin" "-/usr/bin" ];
      };
    };

    environment.persistence."/nix/persist/system".directories = [
      { directory = "/var/cache/kanidm-unixd"; user = "kanidm-unixd"; group = "kanidm-unixd"; mode = "u=rwx,g=,o="; }
    ];
  };
}
