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
            oidc_issuer_url = "https://auth.foxden.network/oauth2/openid/${svcConfig.oAuth.clientId}"
          '';
          user = "root";
          group = "root";
          mode = "0600";
        };

        sops.secrets."${serviceName}" = {};

        foxDen.services.kanidm.oauth2.${svcConfig.oAuth.clientId} = mkOauthConfig inputs;

        systemd.services.${serviceName} = {
          restartTriggers = [ config.environment.etc.${configFileEtc}.text ];
          serviceConfig = {
            DynamicUser = true;

            LoadCredential = "oauth2-proxy.conf:${configFile}";
            EnvironmentFile = config.sops.secrets."${serviceName}".path;

            ExecStart = "${cmd} --config=\"\${CREDENTIALS_DIRECTORY}/oauth2-proxy.conf\"";
          };
          wantedBy = ["multi-user.target"];
        };
      }
    ]);
  });

  mkCaddyInternalBypass = (handler: svcConfig: if svcConfig.oAuth.bypassInternal then ''
    @internal {
      client_ip private_ranges
    }

    handle @internal {
      ${handler}
    }
  '' else "");

  mkCaddyHandler = (handler: svcConfig: if (svcConfig.oAuth.enable && (!svcConfig.oAuth.overrideService)) then ''
    handle /oauth2/* {
      reverse_proxy 127.0.0.1:4180 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Uri {uri}
      }
    }

    ${mkCaddyInternalBypass handler svcConfig}

    handle {
      forward_auth 127.0.0.1:4180 {
        uri /oauth2/auth
        header_up X-Real-IP {remote_host}
        # Make sure to configure the --set-xauthrequest flag to enable this feature.
        copy_headers X-Auth-Request-User X-Auth-Request-Email
        @error status 401
        handle_response @error {
          redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
        }
      }

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

  mkOptions = (inputs@{ ... } : with nixpkgs.lib.types; {
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
    package ? pkgs.caddy,
    webdav ? false,
    rawConfig ? null,
    ...
  }:
    let
      name = inputs.name;

      caddyStorageRoot = "/var/lib/foxden/${name}";

      host = foxDenLib.hosts.getByName config svcConfig.host;
      matchPrefix = if svcConfig.tls then "" else "http://";

      # TODO: Go back to uniqueStrings once next NixOS stable
      dnsMatchers = nixpkgs.lib.lists.unique (nixpkgs.lib.flatten (map (iface:
                      (map (dns: "${matchPrefix}${foxDenLib.global.dns.mkHost dns}") ([iface.dns] ++ iface.cnames)))
                        (nixpkgs.lib.filter (iface: iface.dns.name != "")
                          (nixpkgs.lib.attrsets.attrValues host.interfaces))));

      svc = services.mkNamed name inputs;
      caddyFilePath = "${svc.configDir}/Caddyfile.${name}";

      trustedProxies = config.foxDen.services.trustedProxies;
      mkTrustedProxies = (prefix:
                          if (builtins.length trustedProxies) > 0
                            then (prefix + " " + (nixpkgs.lib.strings.concatStringsSep " " trustedProxies))
                            else "#${prefix} none");

      caddyFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" caddyFilePath;
    in
    {
      config = (nixpkgs.lib.mkMerge [
        svc.config
        (nixpkgs.lib.mkIf (svcConfig.oAuth.enable && (!svcConfig.oAuth.overrideService)) (mkOauthProxy inputs).config)
        {
          environment.etc.${caddyFileEtc} = {
            text = ''
              {
                storage file_system {
                  root ${caddyStorageRoot}
                }
                servers {
                  listener_wrappers {
                    proxy_protocol {
                      timeout 5s
                      ${mkTrustedProxies "allow"}
                    }
                    tls
                  }
                  trusted_proxies_strict
                  ${mkTrustedProxies "trusted_proxies static"}
                }
                ${if webdav then "order webdav before file_server" else ""}
              }

              http:// {
                # Required dummy empty section
              }
            ''
            + (if rawConfig != null then rawConfig else ''
              ${builtins.concatStringsSep ", " dnsMatchers} {
                # Custom config can be injected here
                ${inputs.extraConfig or ""}
                # Auto generated config below
                ${mkCaddyHandler inputs.target svcConfig}
              }
            '');
            mode = "0600";
          };

          systemd.services.${name} = {
            restartTriggers = [ config.environment.etc.${caddyFileEtc}.text ];
            serviceConfig = {
              DynamicUser = true;

              StateDirectory = nixpkgs.lib.strings.removePrefix "/var/lib/" caddyStorageRoot;

              LoadCredential = "Caddyfile:${caddyFilePath}";
              Environment = [
                "\"XDG_CONFIG_HOME=${caddyStorageRoot}\""
                "\"XDG_DATA_HOME=${caddyStorageRoot}\""
                "\"HOME=${caddyStorageRoot}\""
              ];

              ExecStart = "${package}/bin/caddy run --config \"\${CREDENTIALS_DIRECTORY}/Caddyfile\"";
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ]);
    });
}
