{ pkgs, lib, config, options, kanidmOauth2, kanidmExternalIPs, foxDenLib, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.kanidm.server;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
in
{
  options.foxDen.services.kanidm = with lib.types; {
    oauth2 = options.services.kanidm.provision.systems.oauth2;
    externalIPs = lib.mkOption {
      type = uniq (listOf foxDenLib.types.ip);
      default = [ ];
      description = "List of external IPs that will access kanidm internal endpoints.";
    };
    server = {
      enable = lib.mkEnableOption "kanidm server";
  } // (services.http.mkOptions { svcName = "kanidm"; name = "Kanidm server"; });
  };

  options.services.kanidm.provision = {
    groups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (groupSubmod: {
          options = {
            enableUnix = lib.mkEnableOption "manage UNIX attributes";
            gidNumber = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.u32;
              default = null;
              description = "GID number for UNIX group.";
            };
          };
        })
      );
    };
    persons = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (groupSubmod: {
          options = {
            enableUnix = lib.mkEnableOption "manage UNIX attributes";
            gidNumber = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.u32;
              default = null;
              description = "GID number for UNIX group.";
            };
            loginShell = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Login shell for UNIX user.";
            };
          };
        })
      );
    };
  };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "kanidm";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "kanidm-pre";
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-kanidm";
      target = ''
        @denied {
          path /v1/*
          not client_ip private_ranges ${lib.concatStringsSep " " kanidmExternalIPs}
          not path /v1/auth /v1/auth/* /v1/self /v1/self/* /v1/credential /v1/credential/* /v1/jwk /v1/jwk/* /v1/reauth /v1/reauth/* /v1/oauth2 /v1/oauth2/*
        }
        respond @denied "foxden.network intranet only" 403

        reverse_proxy https://127.0.0.1:8443 {
          transport http {
            tls
            tls_insecure_skip_verify
          }
        }
      '';
    }).config
    {
      sops.secrets."kanidm-admin-password" = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "kanidm";
        group = "kanidm";
      };

      sops.secrets."kanidm-idm_admin-password" = config.lib.foxDen.sops.mkIfAvailable {
        mode = "0400";
        owner = "kanidm";
        group = "kanidm";
      };

      services.kanidm = {
        enableServer = true;
        provision = config.lib.foxDen.sops.mkIfAvailable {
          enable = true;

          adminPasswordFile = config.sops.secrets."kanidm-admin-password".path;
          idmAdminPasswordFile = config.sops.secrets."kanidm-idm_admin-password".path;

          autoRemove = true;

          systems.oauth2 = kanidmOauth2;
          groups = {
            login-users = {
              present = true;
              enableUnix = true;
              gidNumber = 4242;
              overwriteMembers = true;
              members = [ "doridian" "wizzy" ];
            };
            superadmins = {
              present = true;
              enableUnix = true;
              gidNumber = 4269;
              overwriteMembers = true;
              members = [ "doridian" "wizzy" ];
            };
          };
          persons = {
            doridian = {
              present = true;
              enableUnix = true;
              gidNumber = 2006;
              loginShell = "/usr/bin/fish";
              displayName = "Doridian";
              mailAddresses = [ "doridian@foxden.network" ];
            };
            wizzy = {
              present = true;
              enableUnix = true;
              gidNumber = 2010;
              displayName = "Wizzy";
              mailAddresses = [ "demwizzy@gmail.com" ];
            };
          };
        };
        serverSettings = {
          version = "2";

          origin = "https://${hostName}";
          domain = hostName;

          tls_chain = "/var/lib/foxden/caddy-kanidm/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.crt";
          tls_key = "/var/lib/foxden/caddy-kanidm/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.key";

          http_client_address_info.x-forward-for = ["127.0.0.1" "127.0.0.0/8"];
        };
      };

      systemd.services.caddy-kanidm = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "kanidm";
          Group = "kanidm";
        };
      };
    
      systemd.services.kanidm-pre = {
        serviceConfig = {
          ExecStart = [
            "${pkgs.coreutils}/bin/mkdir -p /var/lib/kanidm/backups"
          ];
          StateDirectory = "kanidm";
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "no";
          User = "kanidm";
          Group = "kanidm";
        };
      };

      systemd.services.kanidm = {
        after = [ "kanidm-pre.service" ];
        requires = [ "kanidm-pre.service" ];

        serviceConfig = {
          BindReadOnlyPaths = [
            "/var/lib/foxden/caddy-kanidm/certificates/acme-v02.api.letsencrypt.org-directory"
          ];
          StateDirectory = "kanidm";
        };
      };

      environment.persistence."/nix/persist/kanidm" = {
        hideMounts = true;
        directories = [
          { directory = "/var/lib/kanidm"; user = "kanidm"; group = "kanidm"; mode = "u=rwx,g=,o="; }
        ];
      };
    }
  ]);
}
