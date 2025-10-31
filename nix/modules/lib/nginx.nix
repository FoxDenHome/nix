{ nixpkgs, ... }:
{
    mkProxiesConf = config: builtins.toFile "proxies.conf" (nixpkgs.lib.concatStringsSep "\n" (map (ip: "set_real_ip_from ${ip};") config.foxDen.services.trustedProxies));
}
