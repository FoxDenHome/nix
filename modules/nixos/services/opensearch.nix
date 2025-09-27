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

      services.opensearch.settings = {
        "plugins.security.disabled" = false;
        "plugins.security.ssl.transport.keystore_filepath" = "/var/run/opensearch/keystore";

        "http.xff.enabled" = true;
        "http.xff.internalProxies" = "127.0.0.1";

        "authc.proxy_auth_domain.http_enabled" = true;
        "authc.proxy_auth_domain.transport_enabled" = true;
        "authc.proxy_auth_domain.order" = 0;
        "authc.proxy_auth_domain.http_authenticator.type" = "proxy";
        "authc.proxy_auth_domain.http_authenticator.challenge" = false;
        "authc.proxy_auth_domain.http_authenticator.config.user_header" = "x-auth-user";
        "authc.proxy_auth_domain.authentication_backend.type" = "noop";
      };

      systemd.services.opensearch-uds = {
        serviceConfig = {
          DynamicUser = true;
          Type = "simple";
          RuntimeDirectory = "opensearch";
          ExecStart = ["${udsProxyPkg}/bin/uds-proxy -socket /run/opensearch/opensearch.sock -socket-mode 0777 -force-remote-host 127.0.0.1:9200"];
        };
        wantedBy = ["multi-user.target"];
      };

      environment.systemPackages = [
        udsProxyPkg
      ];
    }
  ]);
}
