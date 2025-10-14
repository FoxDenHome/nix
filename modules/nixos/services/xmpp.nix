{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  mkDir = (dir: {
    directory = dir;
    user = config.services.prosody.user;
    group = config.services.prosody.group;
    mode = "u=rwx,g=,o=";
  });

  svcConfig = config.foxDen.services.xmpp;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;

  tlsChain = "/var/lib/foxden/caddy-prosody/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.crt";
  tlsKey = "/var/lib/foxden/caddy-prosody/certificates/acme-v02.api.letsencrypt.org-directory/${hostName}/${hostName}.key";
in
{
  options.foxDen.services.xmpp = {
  } // (services.http.mkOptions { svcName = "xmpp"; name = "Prosody XMPP"; });

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "prosody";
      inherit svcConfig pkgs config;
    }).config
    (lib.mkIf svcConfig.enableHttp (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-prosody";
      target = "reverse_proxy 127.0.0.1:8000";
    }).config)
    {
      systemd.services.caddy-prosody = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = config.services.prosody.user;
          Group = config.services.prosody.group;
        };
      };

      systemd.services.prosody = {
        serviceConfig = {
          StateDirectory = "prosody";
          BindReadOnlyPaths = [
            tlsChain
            tlsKey
          ];
        };
      };

      services.prosody = {
        enable = true;
        admins = [
          "doridian@foxden.network"
        ];
        ssl.cert = tlsChain;
        ssl.key = tlsKey;
        virtualHosts."foxden.network" = {
          enabled = true;
          domain = "foxden.network";
          ssl.cert = tlsChain;
          ssl.key = tlsKey;
        };
        muc = [ {
          domain = "muc.xmpp.foxden.network";          
        } ];
        httpFileShare = {
          domain = "https://upload.xmpp.foxden.network";
          size_limit = 1024 * 1024 * 1000;
          daily_quota = 10 * 1024 * 1024 * 1000;
          expires_after = 60 * 60 * 24 * 7;
        };
        package = pkgs.prosody.override {
          withCommunityModules = [
            "cloud_notify_extensions"
            "cloud_notify_encrypted"
            "cloud_notify_priority_tag"
            "cloud_notify_filters"
            "compat_roles"
            "discoitems"
            "sasl2"
            "sasl_ssdp"
            "sasl2_bind2"
          ];
        };
      };

      environment.persistence."/nix/persist/prosody" = {
        hideMounts = true;
        directories = [
          (mkDir "/var/lib/prosody")
        ];
      };
    }
  ]);
}
