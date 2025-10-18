{ lib, foxDenLib, config, hostName, ... } :
let
  netConfigFamily = ipWithCidr: ipWithoutCidr: with lib.types; submodule {
    options = {
      address = lib.mkOption {
        type = nullOr ipWithCidr;
        default = null;
      };
      gateway = lib.mkOption {
        type = nullOr ipWithoutCidr;
        default = null;
      };
      dns = lib.mkOption {
        type = nullOr ipWithoutCidr;
        default = null;
      };
    };
  };
in
{
  options.foxDen.ipmiconfig = with lib.types; {
    enable = lib.mkEnableOption "Enable IPMI configuration management";
    network = {
      hostName = lib.mkOption {
        type = str;
        default = "${hostName}-ipmi";
      };
      hostZone = lib.mkOption {
        type = str;
        default = "foxden.network";
      };
      interface = lib.mkOption {
        type = enum [ "shared" "dedicated" "failover" ];
        default = "dedicated";
      };
      mac = lib.mkOption {
        type = str;
      };
      ipv4 = lib.mkOption {
        type = netConfigFamily foxDenLib.types.ipv4WithCidr foxDenLib.types.ipv4WithoutCidr;
        default = {};
      };
      ipv6 = lib.mkOption {
        type = netConfigFamily foxDenLib.types.ipv6WithCidr foxDenLib.types.ipv6WithoutCidr;
        default = {};
      };
    };
  };

  config = let
    ipmiconfig = config.foxDen.ipmiconfig;
    netconfig = ipmiconfig.network;
  in lib.mkIf ipmiconfig.enable {
    foxDen.hosts.hosts.${netconfig.hostName} = {
      interfaces.default = {
        driver = "null";
        useDHCP = true;
        dns = {
          name = netconfig.hostName;
          zone = netconfig.hostZone;
        };
        addresses = lib.lists.filter (val: val != null) [
          netconfig.ipv4.address
          netconfig.ipv6.address
        ];
        mac = netconfig.mac;
      };
    };

    environment.etc."foxden/ipmiconfig.txt".text = ''
      ipmitool lan set 1 ipsrc static
      ipmitool lan set 1 ipaddr ${netconfig.ipv4.address}
      ipmitool lan set 1 netmask TODO
      ipmitool lan set 1 defgw ipaddr ${netconfig.ipv4.gateway}
    '';
  };
}