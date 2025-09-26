{ lib, config, foxDenLib, ... } :
let
  wireguardType = with lib.types; submodule {
    options = {
      host = lib.mkOption {
        type = str;
      };
      interface = submoduleOf (attrsOf anything);
    };
  };

  mkWireguard = (name: { host, interface, ... } : let
    hostCfg = foxDenLib.hosts.getByName config host;
  in
  {
    config.networking.wireguard.interfaces.${name} = lib.mkMerge [
      {
        mtu = lib.mkDefault 1280;
        interfaceNamespace = hostCfg.namespace;
        generatePrivateKeyFile = true;
        privateKeyFile = "/var/lib/wireguard/${name}.key";
      }
      interface
    ];

    config.systemd.services."wireguard-${name}".unitConfig = {
      Requires = [ hostCfg.unit ];
      BindsTo = [ hostCfg.unit ];
      After = [ hostCfg.unit ];
    };
  });
in
  lib.mkMerge [
    {
      options.foxDen.services.wireguard = with lib.types; lib.mkOption {
        type = attrsOf wireguardType;
      };

      config.environment.persistence."/nix/persist/wireguard" = {
        hideMounts = true;
        directories = [ { directory = "/var/lib/wireguard"; mode = "u=rwx,g=,o="; } ];
      };
    }
  ]
  ++ map ({ name, value }: mkWireguard name value) (lib.attrsets.attrsToList config.foxDen.services.wireguard)
