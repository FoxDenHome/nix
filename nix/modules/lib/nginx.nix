{ nixpkgs, ... }:
rec {
    mkProxiesText = prefix: config: nixpkgs.lib.concatStringsSep "\n" (map (ip: "${prefix}set_real_ip_from ${ip};") config.foxDen.services.trustedProxies);
    mkProxiesConf = config: builtins.toFile "proxies.conf" (mkProxiesText "" config);
}
