{ foxDenLib, uds-proxy, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.opensearch;

  udsProxyPkg = uds-proxy.packages.${config.nixpkgs.hostPlatform.system}.default;

  userType = with lib.types; submodule {
    options = {
      indexPatterns = lib.mkOption {
        type = listOf str;
      };
    };
  };

  secCfg."config.yml" = (pkgs.writeTextFile {
    name = "config.yml";
    text = ''
      ---
      _meta:
        type: "config"
        config_version: 2

      config:
        dynamic:
          http:
            xff:
              enabled: true
              internalProxies: '127.0.0.1'
          authc:
            proxy_auth_domain:
              http_enabled: true
              transport_enabled: true
              order: 0
              http_authenticator:
                type: proxy
                challenge: false
                config:
                  user_header: "x-auth-user"
                  roles_header: "x-auth-roles"
              authentication_backend:
                type: noop
    '';
  });

  secCfg."roles.yml" = (pkgs.writers.writeYAML
    "roles.yml"
    ({
      _meta = {
        type = "roles";
        config_version = 2;
      };
    } // (lib.attrsets.mapAttrs (name: user: {
      reserved = false;
      hidden = false;
      index_permissions = [
        {
          index_patterns = user.indexPatterns;
          allowed_actions = [ "*" ];
        }
      ];
      tenant_permissions = [];
    }) svcConfig.users)));

  secCfg."roles_mapping.yml" = (pkgs.writers.writeYAML
    "roles_mapping.yml"
    ({
      _meta = {
        type = "rolesmapping";
        config_version = 2;
      };
      all_access = {
        reserved = true;
        hidden = false;
        backend_roles = [ ];
        hosts = [ ];
        users = [ "root" ];
        and_backend_roles = [ ];
      };
    } // (lib.attrsets.mapAttrs (name: user: {
      reserved = false;
      hidden = false;
      backend_roles = [ ];
      hosts = [ ];
      users = [ name ];
      and_backend_roles = [ ];
    }) svcConfig.users)));

  secCfg."internal_users.yml" = (pkgs.writeTextFile {
    name = "internal_users.yml";
    text = ''
      ---
      _meta:
        type: "internalusers"
        config_version: 2
    '';
  });

  secCfg."nodes_dn.yml" = (pkgs.writeTextFile {
    name = "nodes_dn.yml";
    text = ''
      ---
      _meta:
        type: "nodesdn"
        config_version: 2
    '';
  });

  secCfg."action_groups.yml" = (pkgs.writeTextFile {
    name = "action_groups.yml";
    text = ''
      ---
      _meta:
        type: "actiongroups"
        config_version: 2
    '';
  });

  secCfg."tenants.yml" = (pkgs.writeTextFile {
    name = "tenants.yml";
    text = ''
      ---
      _meta:
        type: "tenants"
        config_version: 2
    '';
  });

  secCfg."whitelist.yml" = (pkgs.writeTextFile {
    name = "whitelist.yml";
    text = ''
      ---
      _meta:
        type: "whitelist"
        config_version: 2
    '';
  });
in
{
  options.foxDen.services.opensearch = services.mkOptions { svcName = "opensearch"; name = "OpenSearch"; } // {
    users = with lib.types; lib.mkOption {
      type = attrsOf userType;
    };
  };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "opensearch";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "opensearch-uds";
      inherit svcConfig pkgs config;
    }).config
    {
      foxDen.services.opensearch.host = "opensearch";
      services.opensearch.enable = true;

      foxDen.hosts.hosts = {
        opensearch.interfaces = {};
      };

      services.opensearch.settings = {
        "plugins.security.disabled" = false;
        "plugins.security.authcz.admin_dn" = [ "CN=opensearch" ];
        "plugins.security.ssl.http.enabled" = true;
        "plugins.security.ssl.http.pemkey_filepath" = "/var/lib/opensearch/config/opensearch.key";
        "plugins.security.ssl.http.pemcert_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "plugins.security.ssl.http.pemtrustedcas_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "plugins.security.ssl.transport.enabled" = true;
        "plugins.security.ssl.transport.pemkey_filepath" = "/var/lib/opensearch/config/opensearch.key";
        "plugins.security.ssl.transport.pemcert_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "plugins.security.ssl.transport.pemtrustedcas_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "transport.ssl.enforce_hostname_verification" = false;
      };

      systemd.services.opensearch-uds = {
        serviceConfig = {
          DynamicUser = true;
          PrivateUsers = "identity";
          Type = "simple";
          RuntimeDirectory = "opensearch-uds";
          ExecStart = ["${udsProxyPkg}/bin/uds-proxy -socket /run/opensearch-uds/opensearch.sock -socket-mode 0777 -remote-https -insecure-skip-verify -force-remote-host 127.0.0.1:9200"];
        };
        wantedBy = ["multi-user.target"];
      };

      systemd.services.opensearch = {
        confinement.packages = [
          pkgs.which
          pkgs.coreutils
          pkgs.curl
          pkgs.bash
          pkgs.gnused
          pkgs.jdk21_headless
        ];

        path = [
          pkgs.which
          pkgs.jdk21_headless
        ];

        serviceConfig = {
          BindReadOnlyPaths = foxDenLib.services.mkEtcPaths [ "opensearch" ];

          ExecStartPre = [
            "${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -keyout /var/lib/opensearch/config/opensearch.key -out /var/lib/opensearch/config/opensearch.crt -sha256 -days 36500 -nodes -subj '/CN=opensearch'"
          ]
          ++ (lib.attrsets.mapAttrsToList (name: file: "${pkgs.coreutils}/bin/cp ${file} /var/lib/opensearch/config/opensearch-security/${name}") secCfg)
          ++ (map (name: "${pkgs.coreutils}/bin/chmod 600 /var/lib/opensearch/config/opensearch-security/${name}") (lib.attrsets.attrNames secCfg));

          ExecStartPost = [
            ""
            (pkgs.writeShellScript "opensearch-start-post-foxden" ''
              set -o errexit -o pipefail -o nounset -o errtrace
              shopt -s inherit_errexit

              # Make sure opensearch is up and running before dependents
              # are started
              while ! ${pkgs.bash}/bin/bash ${pkgs.opensearch}/plugins/opensearch-security/tools/securityadmin.sh -icl -nhnv -cacert /var/lib/opensearch/config/opensearch.crt -cert /var/lib/opensearch/config/opensearch.crt -key /var/lib/opensearch/config/opensearch.key -cd /var/lib/opensearch/config/opensearch-security; do
                sleep 1
              done
            '')
          ];
        };
      };

      environment.systemPackages = [
        udsProxyPkg
        pkgs.openssl
        pkgs.bash
      ];
    }
  ]);
}
