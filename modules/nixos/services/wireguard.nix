{ lib, config, foxDenLib, ... } :
let
  wireguardType = with lib.types; submodule {
    options = {
      host = lib.mkOption {
        type = str;
      };
      interface = lib.mkOption {
        type = attrsOf anything;
      };
    };
  };
in
{
  options.foxDen.services.wireguard = with lib.types; lib.mkOption {
    type = attrsOf wireguardType;
  };

  config.environment.persistence."/nix/persist/wireguard" = {
    hideMounts = true;
    directories = [ { directory = "/var/lib/wireguard"; mode = "u=rwx,g=,o="; } ];
  };

  config.networking.wireguard.interfaces = lib.attrsets.mapAttrs (name: { host, interface, ... }: let
    hostCfg = foxDenLib.hosts.getByName config host;
  in
    lib.mkMerge [
      {
        mtu = lib.mkDefault 1280;
        interfaceNamespace = hostCfg.namespace;
        generatePrivateKeyFile = true;
        privateKeyFile = "/var/lib/wireguard/${name}.key";
      }
      interface
    ]
  ) config.foxDen.services.wireguard;

  config.systemd.services = lib.attrsets.listToAttrs (map ({ name, value }: let
    hostCfg = foxDenLib.hosts.getByName config value.host;
  in
  {
    name = "wireguard-${name}";
    value = {
      unitConfig = {
        Requires = [ hostCfg.unit ];
        BindsTo = [ hostCfg.unit ];
        After = [ hostCfg.unit ];
      };
    };
  }) (lib.attrsets.attrsToList config.foxDen.services.wireguard));
}
