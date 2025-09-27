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

      services.opensearch.settings = {
        "plugins.security.disabled" = false;
        "plugins.security.ssl.transport.pemkey_filepath" = "/var/lib/opensearch/config/opensearch.key";
        "plugins.security.ssl.transport.pemcert_filepath" = "/var/lib/opensearch/config/opensearch.crt";
        "plugins.security.ssl.transport.pemtrustedcas_filepath" = "/var/lib/opensearch/config/opensearch.crt";
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
        serviceConfig = {
          BindReadOnlyPaths = foxDenLib.services.mkEtcPaths [ "opensearch" ];

          ExecStartPre = [
            "${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -keyout /var/lib/opensearch/config/opensearch.key -out /var/lib/opensearch/config/opensearch.crt -sha256 -days 36500 -nodes -subj '/CN=opensearch'"
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/opensearch/config/opensearch-security"
            "${pkgs.coreutils}/bin/cp /etc/opensearch/security/config.yml /var/lib/opensearch/config/opensearch-security/config.yml"
          ];

          ExecStartPost = [ "" ];
        };
      };

      environment.systemPackages = [
        udsProxyPkg
        pkgs.openssl
      ];
    }
  ]);
}
