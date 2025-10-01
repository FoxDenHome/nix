{ lib, config, ... } :
{
    environment.etc."foxden/nginx-proxies.conf" = {
      text = lib.concatStringsSep "\n" (map (ip: "set_real_ip_from ${ip};") config.foxDen.hosts.trustedProxies);
    };
}
