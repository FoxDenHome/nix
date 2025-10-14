{ lib, config, foxDenLib, ... } :
{
  options.foxDen.services.kanidm.login = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable kanidm login";
  };

  config = lib.mkIf config.foxDen.services.kanidm.login {
    security.wrappers."kanidm_ssh_authorizedkeys" = {
      source = "${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys";
      owner = "root";
      group = "root";
    };

    # BEGIN: Fix "normal" shells
    environment.shells = [
      "/usr/bin/fish"
      "/usr/bin/zsh"
      "/usr/bin/bash"
    ];
    systemd.tmpfiles.rules = [
      "L /usr/bin/bash - - - - /run/current-system/sw/bin/bash"
      "L /usr/bin/fish - - - - /run/current-system/sw/bin/fish"
      "L /usr/bin/zsh - - - - /run/current-system/sw/bin/zsh"
    ];

    systemd.services.kanidm-unixd = {
      serviceConfig = {
        BindReadOnlyPaths = [
          "-/usr/bin"
        ] ++ (foxDenLib.services.mkEtcPaths [
          "shells"
        ]);
      };
    };
    # END: Fix "normal" shells

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
        default_shell = "/run/current-system/sw/bin/fish";
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
