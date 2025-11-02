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
            set_xauthrequest = true

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
    #  $_{handler}
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
      error_page 401 =307 /oauth2/sign_in;

      auth_request_set $user $upstream_http_x_auth_request_user;
      auth_request_set $email $upstream_http_x_auth_request_email;
      proxy_set_header X-User $user;
      proxy_set_header X-Email $email;
      ${handler}
    }
  '' else ''
    location / {
      ${handler}
    }
  '');
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
    customReadyz = nixpkgs.lib.mkEnableOption "Don't handle /readyz endpoint for custom health checks";
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
    dynamicUser ? true,
    modules ? [],
    rawConfig ? null,
    ...
  }:
    let
      name = inputs.name;

      package = pkgs.nginxQuic.override {
        modules = nixpkgs.lib.lists.unique ([
          pkgs.nginxModules.njs
        ] ++ modules);
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

      readyzConf = enabled: if enabled then ''
        location = /readyz {
          add_header Content-Type text/plain always;
          return 200 "OK";
        }
      '' else ''
        # Normal /readyz handling disabled
      '';

      proxyConfigNoHost = ''
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_buffering off;
        fastcgi_request_buffering off;
        fastcgi_buffering off;
        client_max_body_size 0;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        include ${package}/conf/fastcgi_params;
      '';
      proxyConfig = ''
        ${proxyConfigNoHost}
        proxy_set_header Host $host;
      '';
      defaultTarget = ''
        ${proxyConfig}
        ${inputs.target}
      '';
      hostConfig = ''
        # Custom config can be injected here
        ${inputs.extraConfig or ""}
        # Auto generated config below
        ${mkNginxHandler defaultTarget svcConfig}
      '';
      baseHttpConfig = readyz: first: let
        proxyOpts = if first then "proxy_protocol" else "";
      in ''
        listen 80;
        listen [::]:80;
        listen 81 ${proxyOpts};
        listen [::]:81 ${proxyOpts};

        location @acmePeriodicAuto {
          js_periodic acme.clientAutoMode interval=1m;
        }

        location /.well-known/acme-challenge/ {
          js_content acme.challengeResponse;
        }

        ${readyzConf readyz}
      '';
      baseHttpsConfig = readyz: first: let
        proxyOpts = if first then "proxy_protocol" else "";
        reuseportOpts = if first then "reuseport" else "";
        sslOpts = if first then "ssl" else "";
      in ''
        listen 443 ${sslOpts};
        listen [::]:443 ${sslOpts};
        listen 443 quic ${reuseportOpts};
        listen [::]:443 quic ${reuseportOpts};
        listen 444 ${sslOpts} ${proxyOpts};
        listen [::]:444 ${sslOpts} ${proxyOpts};
        http2 on;

        js_set $dynamic_ssl_cert acme.js_cert;
        js_set $dynamic_ssl_key acme.js_key;
        ssl_certificate data:$dynamic_ssl_cert;
        ssl_certificate_key data:$dynamic_ssl_key;

        location /.well-known/acme-challenge/ {
          js_content acme.challengeResponse;
        }

        ${readyzConf readyz}
      '';
      useStockReadyz = !svcConfig.customReadyz;
      baseWebConfig = first: if svcConfig.tls then baseHttpsConfig useStockReadyz first else baseHttpConfig useStockReadyz first;

      normalConfig = ''server {
        server_name ${builtins.concatStringsSep " " hostMatchers};
        ${baseWebConfig true}
        ${hostConfig}
      }'';
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
                worker_connections 1024;
              }

              http {
                access_log off;
                log_not_found off;

                include ${package}/conf/mime.types;
                default_type application/octet-stream;

                sendfile on;
                keepalive_timeout 65;

                resolver ${nixpkgs.lib.strings.concatStringsSep " " (map foxDenLib.util.bracketIPv6 host.nameservers)};

                ${foxDenLib.nginx.mkProxiesText "  " config}

                js_path "/njs/lib/";
                js_fetch_trusted_certificate /etc/ssl/certs/ca-certificates.crt;

                ${if svcConfig.tls then ''
                js_var $njs_acme_server_names "${builtins.concatStringsSep " " hostMatchers}";
                js_var $njs_acme_account_email "ssl@foxden.network";
                js_var $njs_acme_dir "${storageRoot}/acme";
                js_var $njs_acme_directory_uri "https://acme-v02.api.letsencrypt.org/directory";
                js_shared_dict_zone zone=acme:1m;
                js_import acme from acme.js;

                server {
                  server_name ${builtins.concatStringsSep " " hostMatchers};
                  ${baseHttpConfig true true}

                  location / {
                    return 301 https://$http_host$request_uri;
                  }
                }
                '' else ""}

              ${if rawConfig != null then rawConfig { inherit package baseWebConfig proxyConfig proxyConfigNoHost; } else normalConfig}
              }
            '';
            mode = "0600";
          };

          foxDen.hosts.hosts.${svcConfig.host}.webservice.enable = true;

          systemd.services.${name} = {
            restartTriggers = [ config.environment.etc.${confFileEtc}.text ];
            serviceConfig = {
              DynamicUser = dynamicUser;
              StateDirectory = nixpkgs.lib.strings.removePrefix "/var/lib/" storageRoot;
              LoadCredential = "nginx.conf:${confFilePath}";
              ExecStartPre =[ "${pkgs.coreutils}/bin/mkdir -p ${storageRoot}/acme" ];
              BindPaths = if dynamicUser then [ ] else [ storageRoot ];
              BindReadOnlyPaths = [
                "${pkgs.fetchurl {
                  url = "https://github.com/nginx/njs-acme/releases/download/v1.0.0/acme.js";
                  hash = "sha256-Gu+3Ca/C7YHAf7xfarZYeC/pnohWnuho4l06bx5TVcs=";
                }}:/njs/lib/acme.js"
              ];
              ExecStart = "${package}/bin/nginx -g 'daemon off;' -e stderr -c \"\${CREDENTIALS_DIRECTORY}/nginx.conf\"";
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ]);
    });
}
