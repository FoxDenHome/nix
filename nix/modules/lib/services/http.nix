{ nixpkgs, foxDenLib, ... }:
let
  services = foxDenLib.services;
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkOauthConfig = ({ config, svcConfig, oAuthCallbackUrl ? "/oauth2/callback", ... }: let
    host = foxDenLib.hosts.getByName config svcConfig.host;
    baseUrlPrefix = if svcConfig.tls then "https://" else "http://";
    # TODO: Go back to uniqueStrings once next NixOS stable
    baseUrls = nixpkgs.lib.lists.unique (nixpkgs.lib.flatten (map (iface:
                    (map (dns: "${baseUrlPrefix}${foxDenLib.global.dns.mkHost dns}") ([iface.dns] ++ iface.cnames)))
                      (nixpkgs.lib.filter (iface: iface.dns.name != "")
                        (nixpkgs.lib.attrsets.attrValues host.interfaces))));
  in
  {
    present = true;
    public = true;
    displayName = svcConfig.oAuth.displayName;
    originUrl = map (url: "${url}${oAuthCallbackUrl}") baseUrls;
    originLanding = nixpkgs.lib.lists.head baseUrls;
    scopeMaps.login-users = ["preferred_username" "email" "openid" "profile"];
  });

  mkOauthProxy = (inputs@{ config, svcConfig, pkgs, ... }: let
    name = inputs.name;
    serviceName = "oauth2-proxy-${name}";

    svc = services.mkNamed serviceName inputs;
    cmd = (eSA "${pkgs.oauth2-proxy}/bin/oauth2-proxy");
    secure = if svcConfig.tls then "true" else "false";

    configFile = "${svc.configDir}/${name}.conf";
    configFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" configFile;

    cookieSecretFile = "/run/${serviceName}/cookie-secret";
  in
  {
    config = (nixpkgs.lib.mkMerge [
      svc.config
      {
        environment.etc.${configFileEtc} = {
          text = ''
            http_address = "127.0.0.1:4180"
            reverse_proxy = true
            provider = "oidc"
            provider_display_name = "FoxDen"
            code_challenge_method = "S256"
            email_domains = ["*"]
            scope = "openid email profile"
            cookie_name = "_oauth2_proxy"
            cookie_expire = "168h"
            cookie_httponly = true
            cookie_secure = ${secure}
            skip_provider_button = true

            client_id = "${svcConfig.oAuth.clientId}"
            client_secret = "PKCE"
            cookie_secret_file = "${cookieSecretFile}"
            oidc_issuer_url = "https://auth.foxden.network/oauth2/openid/${svcConfig.oAuth.clientId}"
          '';
          user = "root";
          group = "root";
          mode = "0600";
        };

        foxDen.services.kanidm.oauth2.${svcConfig.oAuth.clientId} = mkOauthConfig inputs;

        systemd.services.${serviceName} = {
          restartTriggers = [ config.environment.etc.${configFileEtc}.text ];
          serviceConfig = {
            DynamicUser = true;
            ExecStartPre = [
              (pkgs.writeShellScript "generate-cookie-secret" ''
                if [ ! -f ${cookieSecretFile} ]; then
                  ${pkgs.coreutils}/bin/dd if=/dev/urandom bs=16 count=1 | ${pkgs.coreutils}/bin/base64 -w 0 > ${cookieSecretFile}
                fi
                ${pkgs.coreutils}/bin/chmod 600 ${cookieSecretFile}
              '')
            ];
            RuntimeDirectory = serviceName;
            RuntimeDirectoryMode = "0700";
            LoadCredential = "oauth2-proxy.conf:${configFile}";
            ExecStart = "${cmd} --config=\"\${CREDENTIALS_DIRECTORY}/oauth2-proxy.conf\"";
          };
          wantedBy = ["multi-user.target"];
        };
      }
    ]);
  });

  mkNginxInternalBypass = (handler: svcConfig: if svcConfig.oAuth.bypassInternal then ''
    #@internal {
    #  client_ip private_ranges
    #}

    #handle @internal {
    #  ${handler}
    #}
  '' else "");

  mkNginxHandler = (handler: svcConfig: if (svcConfig.oAuth.enable && (!svcConfig.oAuth.overrideService)) then ''
    location /oauth2/ {
      proxy_pass http://127.0.0.1:4180;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
    }
    location = /oauth2/auth {
      proxy_pass http://127.0.0.1:4180;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Uri $request_uri;
      # nginx auth_request includes headers but not body
      proxy_set_header Content-Length "";
      proxy_pass_request_body off;
    }
    ${mkNginxInternalBypass handler svcConfig}

    location / {
      auth_request /oauth2/auth;
      error_page 401 =403 /oauth2/sign_in;

      auth_request_set $user $upstream_http_x_auth_request_user;
      auth_request_set $email $upstream_http_x_auth_request_email;
      proxy_set_header X-User $user;
      proxy_set_header X-Email $email;

      ${handler}
    }
  '' else handler);
in
{
  nixosModule = { ... }:
  {
    options.foxDen.services.trustedProxies = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = listOf foxDenLib.types.ip;
      default = [];
    };

    config.foxDen.services.trustedProxies = [
      "10.1.0.0/23"
      "10.2.0.0/23"
      "10.3.0.0/23"
      "10.4.0.0/23"
      "10.5.0.0/23"
      "10.6.0.0/23"
      "10.7.0.0/23"
      "10.8.0.0/23"
      "10.9.0.0/23"
    ];
  };

  inherit mkOauthConfig;

  mkOptions = (inputs@{ ... }: with nixpkgs.lib.types; {
    tls = nixpkgs.lib.mkEnableOption "TLS";
    oAuth = {
      enable = nixpkgs.lib.mkEnableOption "OAuth2 Proxy";
      bypassInternal = nixpkgs.lib.mkEnableOption "Bypass OAuth for internal requests";
      overrideService = nixpkgs.lib.mkEnableOption "Don't setup OAuth2 Proxy service, the service has special handling";
      clientId = nixpkgs.lib.mkOption {
        type = str;
      };
      displayName = nixpkgs.lib.mkOption {
        type = str;
      };
    };
  } // (services.mkOptions inputs));

  make = (inputs@{
    config,
    svcConfig,
    pkgs,
    modules ? [],
    webdav ? false,
    rawConfig ? null,
    ...
  }:
    let
      name = inputs.name;

      package = pkgs.nginxQuic.override {
        modules = [
          pkgs.nginxModules.acme
        ] ++ modules;
      };

      storageRoot = "/var/lib/foxden/${name}";

      host = foxDenLib.hosts.getByName config svcConfig.host;

      # TODO: Go back to uniqueStrings once next NixOS stable
      hostMatchers = nixpkgs.lib.lists.unique (nixpkgs.lib.flatten (map (iface:
                      (map foxDenLib.global.dns.mkHost ([iface.dns] ++ iface.cnames)))
                        (nixpkgs.lib.filter (iface: iface.dns.name != "")
                          (nixpkgs.lib.attrsets.attrValues host.interfaces))));

      svc = services.mkNamed name inputs;
      confFilePath = "${svc.configDir}/nginx.conf";
      confFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" confFilePath;

      defaultTarget = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        ${inputs.target}
      '';

      hostConfig = ''
        # TODO: ${if webdav then "order webdav before file_server" else ""}
        # Custom config can be injected here
        ${inputs.extraConfig or ""}
        # Auto generated config below
        ${mkNginxHandler defaultTarget svcConfig}
      '';

      baseHttpConfig = ''
        listen 80;
        listen [::]:80;
        listen 81 proxy_protocol;
        listen [::]:81 proxy_protocol;
      '';
      baseHttpsConfig = ''
        listen 443 ssl;
        listen [::]:443 ssl;
        listen 443 quic reuseport;
        listen [::]:443 quic reuseport;
        listen 444 ssl proxy_protocol;
        listen [::]:444 ssl proxy_protocol;

        acme_certificate main;
        ssl_certificate $acme_certificate;
        ssl_certificate_key $acme_certificate_key;
        # do not parse the certificate on each request
        ssl_certificate_cache max=2;
      '';
      baseWebConfig = if svcConfig.tls then baseHttpsConfig else baseHttpConfig;

      normalConfig = ''server {
        server_name ${builtins.concatStringsSep " " hostMatchers};

        ${baseHttpConfig}

        ${if svcConfig.tls then ''location / {
          return 301 https://$http_host$request_uri;
        }'' else hostConfig}
      }''
      + (if svcConfig.tls then ''server {
        server_name ${builtins.concatStringsSep " " hostMatchers};

        listen 443 ssl;
        listen [::]:443 ssl;
        listen 443 quic reuseport;
        listen [::]:443 quic reuseport;
        listen 444 ssl proxy_protocol;
        listen [::]:444 ssl proxy_protocol;

        acme_certificate main;
        ssl_certificate $acme_certificate;
        ssl_certificate_key $acme_certificate_key;
        # do not parse the certificate on each request
        ssl_certificate_cache max=2;

      ${hostConfig}
      }'' else "");
    in
    {
      config = (nixpkgs.lib.mkMerge [
        svc.config
        (nixpkgs.lib.mkIf (svcConfig.oAuth.enable && (!svcConfig.oAuth.overrideService)) (mkOauthProxy inputs).config)
        {
          environment.etc.${confFileEtc} = {
            text = ''
              worker_processes auto;

              error_log stderr notice;
              pid /tmp/nginx.pid;

              events {
                  worker_connections  1024;
              }

              http {
                access_log off;

                include ${package}/conf/mime.types;
                default_type application/octet-stream;

                sendfile on;
                keepalive_timeout 65;

                resolver ${nixpkgs.lib.strings.concatStringsSep " " (map foxDenLib.util.bracketIPv6 host.nameservers)};
              ${foxDenLib.nginx.mkProxiesText "  " config}

                acme_issuer main {
                    uri         https://acme-v02.api.letsencrypt.org/directory;
                    contact     ssl@foxden.network;
                    state_path  ${storageRoot}/acme-main;
                    accept_terms_of_service;
                }
                acme_shared_zone zone=ngx_acme_shared:1M;

              ${if rawConfig != null then rawConfig { inherit baseHttpConfig baseHttpsConfig baseWebConfig; } else normalConfig}
              }
            '';
            mode = "0600";
          };

          systemd.services.${name} = {
            restartTriggers = [ config.environment.etc.${confFileEtc}.text ];
            serviceConfig = {
              DynamicUser = true;
              StateDirectory = nixpkgs.lib.strings.removePrefix "/var/lib/" storageRoot;
              LoadCredential = "nginx.conf:${confFilePath}";
              ExecStart = "${package}/bin/nginx -e stderr -c \"\${CREDENTIALS_DIRECTORY}/nginx.conf\"";
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ]);
    });
}
