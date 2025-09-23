{ nixpkgs, ... }:
let
  hosts = import ./hosts.nix { inherit nixpkgs; };
  eSA = nixpkgs.lib.strings.escapeShellArg;

  make = (svc: { host, ... }:
    let
      info = hosts.mkHostInfo host;
    in
    {
      # oci.networks = [ "ns:${info.namespace}" ]; # TODO: Test
      systemd.services.${svc} = {
        unitConfig = {
          Requires = [ info.unit ];
          BindsTo = [ info.unit ];
          After = [ info.unit ];
        };

        serviceConfig = {
          NetworkNamespacePath = info.namespace;
          DevicePolicy = "closed";
          PrivateTmp = true;
          PrivateMounts = true;
          ProtectSystem = "strict";
          ProtectHome = "tmpfs";
          Restart = nixpkgs.lib.mkForce "always";
        };
      };
    });

  mkOauthProxy = (inputs@{ config, svcConfig, pkgs, target, ... }: let
    name = inputs.name or inputs.host;
    serviceName = "oauth2-proxy-${name}";

    svc = make serviceName inputs;
    cmd = (eSA "${pkgs.oauth2-proxy}/bin/oauth2-proxy");
    secure = if svcConfig.tls then "true" else "false";

    configFile = "/etc/foxden/oauth2-proxy/${name}.conf";
    configFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" configFile;

  in
  (nixpkgs.lib.mkMerge [
    svc
    {
      users.users.${serviceName} = {
        isSystemUser = true;
        group = serviceName;
      };
      users.groups.${serviceName} = {};

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
        user = serviceName;
        group = serviceName;
        mode = "0600";
      };

      systemd.services.${serviceName} = {
        restartTriggers = [ config.environment.etc.${configFileEtc}.text ];
        serviceConfig = {
          ExecStart = "${cmd} --config=${eSA configFile}";
          User = serviceName;
          Group = serviceName;
          Restart = "always";
        };
        wantedBy = ["multi-user.target"];
      };
    }
  ]));

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

  mkOptions = { name }: {
    enable = nixpkgs.lib.mkEnableOption name;
  };
in
{
  nixosModules.services = { ... }:
  {
    options.foxDen.services.trustedProxies = with nixpkgs.lib.types; nixpkgs.lib.mkOption {
      type = listOf str;
      default = [];
    };
  };

  mkCustom = (inputs@{ host, ... }: make (inputs.name or host) inputs);

  mkHttpOptions = (inputs@{ ... } : with nixpkgs.lib.types; nixpkgs.lib.mergeAttrs {
    hostPort = nixpkgs.lib.mkOption {
      type = str;
      default = "";
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
  } (mkOptions inputs));
  mkOptions = mkOptions;

  mkCaddy = (inputs@{ config, svcConfig, pkgs, target, ... }:
    let
      name = inputs.name or inputs.host;

      caddyStorageRoot = "/var/lib/foxden/caddy/${name}";
      caddyConfigRoot = "/etc/foxden/caddy/Caddyfile.${name}";

      hostCfg = hosts.mkHostConfig config inputs.host;
      hostPort = if svcConfig.hostPort != "" then svcConfig.hostPort else "${hostCfg.name}.${hostCfg.root}";
      url = (if svcConfig.tls then "" else "http://") + hostPort;

      serviceName = "caddy-${name}";
      svc = make serviceName inputs;
      caddyFilePath = "${caddyConfigRoot}/Caddyfile";
      cmd = (eSA "${pkgs.caddy}/bin/caddy");

      trustedProxies = config.foxDen.services.trustedProxies;
      mkTrustedProxies = (prefix:
                          if (builtins.length trustedProxies) > 0
                            then (prefix + " " + (nixpkgs.lib.strings.concatStringsSep " " trustedProxies))
                            else "#${prefix} none");

      caddyFileEtc = nixpkgs.lib.strings.removePrefix "/etc/" caddyFilePath;
    in
    (nixpkgs.lib.mkMerge [
      svc
      (nixpkgs.lib.mkIf svcConfig.oAuth.enable (mkOauthProxy inputs))
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
          user = serviceName;
          group = serviceName;
          mode = "0600";
        };

        environment.persistence."/nix/persist/foxden/services" = {
          hideMounts = true;
          directories = [
            { directory = caddyStorageRoot; user = serviceName; group = serviceName; mode = "u=rwx,g=,o="; }
          ];
        };

        users.users.${serviceName} = {
          isSystemUser = true;
          group = serviceName;
        };
        users.groups.${serviceName} = {};

        systemd.services.${serviceName} = {
          reloadTriggers = [ config.environment.etc.${caddyFileEtc}.text ];
          serviceConfig = {
            Environment = [
              "XDG_CONFIG_HOME=${caddyStorageRoot}"
              "XDG_DATA_HOME=${caddyStorageRoot}"
            ];
            ExecStart = "${cmd} run --config ${eSA caddyFilePath}";
            ExecReload = "${cmd} reload --config ${eSA caddyFilePath}";
            User = serviceName;
            Group = serviceName;
            Restart = "always";
            ReadWritePaths = [caddyStorageRoot];
            ReadOnlyPaths = [caddyConfigRoot];
            AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          };
          wantedBy = ["multi-user.target"];
        };
      }
    ]));
}
