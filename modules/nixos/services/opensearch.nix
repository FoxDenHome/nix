{ foxDenLib, uds-proxy, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.opensearch;

  udsProxyPkg = uds-proxy.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.opensearch = services.mkOptions { svcName = "opensearch"; name = "OpenSearch"; };

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
      services.opensearch.enable = true;

      environment.etc."opensearch/security/config.yml".text = ''
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
                    roles_header: "x-auth-group"
                authentication_backend:
                  type: noop
      '';

      environment.etc."opensearch/security/internal_users.yml".text = ''
        ---
        _meta:
          type: "internalusers"
          config_version: 2

        root:
          hash: ""
          roles:
          - admin
          reserved: true
          description: "r00t"

        doridian:
          hash: ""
          roles:
          - own_index
          - fadumper
          reserved: false
          description: "foxes"
      '';

      environment.etc."opensearch/security/roles_mapping.yml".text = ''
        ---
        _meta:
          type: "rolesmapping"
          config_version: 2

        own_index:
          reserved: false
          hidden: false
          backend_roles: []
          hosts: []
          users:
          - "*"
          and_backend_roles: []
          description: "Allow full access to an index named like the username"
      '';

      environment.etc."opensearch/security/roless.yml".text = ''
        ---
        _meta:
          type: "roles"
          config_version: 2

        fadumper:
          reserved: false
          hidden: false
          index_permissions:
          - index_patterns:
            - "fadumper_*"
            allowed_actions:
            - "*"

        e621dumper:
          reserved: false
          hidden: false
          index_permissions:
          - index_patterns:
            - "e621dumper_*"
            allowed_actions:
            - "*"
      '';

      services.opensearch.settings = {
        "plugins.security.disabled" = false;
        "plugins.security.authcz.admin_dn" = [ "CN=opensearch" ];
        "plugins.security.ssl.transport.pemkey_filepath" = "/var/lib/opensearch/config/opensearch.key";
        "plugins.security.ssl.transport.pemcert_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "plugins.security.ssl.transport.pemtrustedcas_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "transport.ssl.enforce_hostname_verification" = false;
      };

      systemd.services.opensearch-uds = {
        serviceConfig = {
          DynamicUser = true;
          Type = "simple";
          RuntimeDirectory = "opensearch-uds";
          ExecStart = ["${udsProxyPkg}/bin/uds-proxy -socket /run/opensearch-uds/opensearch.sock -socket-mode 0777 -force-remote-host 127.0.0.1:9200"];
        };
        wantedBy = ["multi-user.target"];
      };

      systemd.services.opensearch = {
        confinement.packages = [
          pkgs.which
        ];

        serviceConfig = {
          BindReadOnlyPaths = [ "/run/current-system/sw/bin" ] ++ foxDenLib.services.mkEtcPaths [ "opensearch" ];

          ExecStartPre = [
            "${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -keyout /var/lib/opensearch/config/opensearch.key -out /var/lib/opensearch/config/opensearch.crt -sha256 -days 36500 -nodes -subj '/CN=opensearch'"
            "${pkgs.coreutils}/bin/rm -rf /var/lib/opensearch/config/opensearch-security"
            "${pkgs.coreutils}/bin/cp --remove-destination -r /etc/opensearch/security /var/lib/opensearch/config/opensearch-security"
            "${pkgs.coreutils}/bin/chmod -R 700 /var/lib/opensearch/config/opensearch-security"
          ];

          ExecStartPost = [
            ""
            "${pkgs.bash}/bin/bash ${pkgs.opensearch}/plugins/opensearch-security/tools/securityadmin.sh -icl -nhnv -cacert /var/lib/opensearch/config/opensearch.crt -cert /var/lib/opensearch/config/opensearch.crt -key /var/lib/opensearch/config/opensearch.key -cd /var/lib/opensearch/config/opensearch-security"
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
