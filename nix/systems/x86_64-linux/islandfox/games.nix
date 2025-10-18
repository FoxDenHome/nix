{ config, ... }:
let
  mkVlanHost = config.lib.foxDenSys.mkVlanHost;
in
{
  foxDen.services = config.lib.foxDen.sops.mkIfAvailable {
    darksignsonline = {
      enable = true;
      domain = "darksignsonline.com";
      host = "darksignsonline";
    };
    minecraft = {
      enable = true;
      host = "minecraft";
    };
    spaceage-api = {
      enable = true;
      host = "spaceage-api";
      tls = true;
    };
    spaceage-website = {
      enable = true;
      host = "spaceage-website";
      tls = true;
    };
    spaceage-tts = {
      enable = true;
      host = "spaceage-tts";
      tls = true;
    };
    spaceage-gmod = {
      enable = true;
      host = "spaceage-gmod";
    };
  };

  foxDen.hosts.hosts = {
    darksignsonline = mkVlanHost 3 {
      dns = {
        name = "darksignsonline";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "@";
          zone = "darksignsonline.com";
          type = "ALIAS";
        }
        {
          name = "www";
          zone = "darksignsonline.com";
        }
      ];
      addresses = [
        "10.3.10.15/16"
        "fd2c:f4cb:63be:3::a0f/64"
      ];
    };
    minecraft = mkVlanHost 3 {
      dns = {
        name = "minecraft";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "mc";
          zone = "foxden.network";
        }
        {
          name = "mc";
          zone = "doridian.net";
        }
      ];
      firewall.portForwards = [
        {
          protocol = "tcp";
          port = 25565;
        }
      ];
      addresses = [
        "10.3.10.8/16"
        "fd2c:f4cb:63be:3::a08/64"
      ];
    };
    spaceage-gmod = mkVlanHost 3 {
      dns = {
        name = "spaceage-gmod";
        zone = "foxden.network";
        dynDns = true;
      };
      cnames = [
        {
          name = "gmod";
          zone = "spaceage.mp";
        }
        {
          name = "play";
          zone = "spaceage.mp";
        }
      ];
      firewall.portForwards = [
        {
          protocol = "udp";
          port = 27015;
        }
      ];
      addresses = [
        "10.3.10.4/16"
        "fd2c:f4cb:63be:3::a04/64"
      ];
    };
    spaceage-api = mkVlanHost 3 {
      dns = {
        name = "spaceage-api";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      cnames = [
        {
          name = "api";
          zone = "spaceage.mp";
        }
      ];
      addresses = [
        "10.3.10.5/16"
        "fd2c:f4cb:63be:3::a05/64"
      ];
    };
    spaceage-tts = mkVlanHost 3 {
      dns = {
        name = "spaceage-tts";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      cnames = [
        {
          name = "tts";
          zone = "spaceage.mp";
        }
      ];
      addresses = [
        "10.3.10.6/16"
        "fd2c:f4cb:63be:3::a06/64"
      ];
    };
    spaceage-website = mkVlanHost 3 {
      dns = {
        name = "spaceage-website";
        zone = "foxden.network";
        dynDns = true;
      };
      snirouter.enable = true;
      cnames = [
        {
          name = "www";
          zone = "spaceage.mp";
        }
        {
          name = "@";
          zone = "spaceage.mp";
          type = "ALIAS";
        }
      ];
      addresses = [
        "10.3.10.9/16"
        "fd2c:f4cb:63be:3::a09/64"
      ];
    };
  };
}
