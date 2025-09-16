{ lib, pkgs, ...} :
{
  services.openssh.authorizedKeysCommand = "${pkgs.kanidm}/bin/kanidm_ssh_authorizedkeys";

  services.kanidm = {
    enableClient = true;
    enablePam = true;

    package = pkgs.kanidm;

    clientSettings = {
      uri = "https://auth.foxden.network";
      verify_ca = true;
      verify_hostnames = true;
    };

    unixSettings = {
      pam_allowed_login_groups = [ "login-users" ];
      allow_local_account_override = [ "share" ];
      uid_attr_map = "name";
      gid_attr_map = "name";
      home_attr = "name";
      home_alias = "none";
    };
  };
}
