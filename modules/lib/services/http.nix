{ nixpkgs, foxDenLib, ... }:
let
  services = foxDenLib.services;
  eSA = nixpkgs.lib.strings.escapeShellArg;

  mkOauthProxy = (inputs@{ config, svcConfig, pkgs, target, ... }: let
    name = inputs.name or svcConfig.host;
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

            cookie_secret = "CHANGE ME RIGHT "
            client_id = "${svcConfig.oAuth.clientId}"
            client_secret = "${svcConfig.oAuth.clientSecret}"
            oidc_issuer_url = "https://auth.foxden.network/oauth2/openid/${svcConfig.oAuth.clientId}"
          '';
          user = "root";
          group = "root";
          mode = "0600";
        };

        systemd.services.${serviceName} = {
          restartTriggers = [ config.environment.etc.${configFileEtc}.text ];
          serviceConfig = {
            DynamicUser = true;
            LoadCredential = "oauth2-proxy.conf:${configFile}";
            ExecStart = "${cmd} --config=\"\${CREDENTIALS_DIRECTORY}/oauth2-proxy.conf\"";
            Restart = "always";
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

  mkCaddyHandler = (handler: svcConfig: if svcConfig.oAuth.enable then ''
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
  };

  mkOptions = (inputs@{ ... } : with nixpkgs.lib.types; {
    hostPort = nixpkgs.lib.mkOption {
      type = nullOr foxDenLib.types.ipWithPort;
      default = null;
    };
    tls = nixpkgs.lib.mkEnableOption "TLS";
    oAuth = {
      enable = nixpkgs.lib.mkEnableOption "OAuth2 Proxy";
      bypassInternal = nixpkgs.lib.mkEnableOption "Bypass OAuth for internal requests";
      clientId = nixpkgs.lib.mkOption {
        type = str;
      };
      clientSecret = nixpkgs.lib.mkOption {
        type = str;
      };
    };
  } // (services.mkOptions inputs));

  make = (inputs@{ config, svcConfig, pkgs, target, ... }:
    let
      name = inputs.name or svcConfig.host;
      serviceName = inputs.serviceName or "caddy-${name}";

      caddyStorageRoot = "/var/lib/foxden/caddy/${name}";

      host = foxDenLib.hosts.getByName config svcConfig.host;
      hostPort = if svcConfig.hostPort != null then svcConfig.hostPort else "${host.dns.name}.${host.dns.zone}";
      url = (if svcConfig.tls then "" else "http://") + hostPort;

      svc = services.mkNamed serviceName inputs;
      caddyFilePath = "${svc.configDir}/Caddyfile.${name}";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");

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
        (nixpkgs.lib.mkIf svcConfig.oAuth.enable (mkOauthProxy inputs).config)
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
              }

              http:// {
                # Required dummy empty section
              }

              ${url} {
                ${mkCaddyHandler target svcConfig}
              }
            '';
            mode = "0600";
          };

          systemd.services.${serviceName} = {
            restartTriggers = [ config.environment.etc.${caddyFileEtc}.text ];
            serviceConfig = {
              DynamicUser = true;
              PrivateUsers = false; # needed for the capabilities sadly
              AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
              StateDirectory = nixpkgs.lib.strings.removePrefix "/var/lib/" caddyStorageRoot;
              LoadCredential = "Caddyfile:${caddyFilePath}";
              Environment = [
                "XDG_CONFIG_HOME=${caddyStorageRoot}"
                "XDG_DATA_HOME=${caddyStorageRoot}"
                "HOME=${caddyStorageRoot}"
              ];
              ExecStart = "${cmd} run --config \"\${CREDENTIALS_DIRECTORY}/Caddyfile\"";
              Restart = "always";
              BindPaths = [caddyStorageRoot];
            };
            wantedBy = ["multi-user.target"];
          };
        }
      ]);
    });
}
