{ lib, config, pkgs, ... } :
{
    proxiesConf = pkgs.writeFile "proxies.conf" lib.concatStringsSep "\n" (map (ip: "set_real_ip_from ${ip};") config.foxDen.services.trustedProxies);
}
