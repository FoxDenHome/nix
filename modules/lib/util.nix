{ nixpkgs, ... }:
let
  mkShortHash = (len: str:
    builtins.substring 0 len (builtins.hashString "sha256" str));

  isPrivateIPv4 = (ip: let
    segments = nixpkgs.lib.strings.splitString "." ip;
    first = nixpkgs.lib.strings.toIntBase10 (builtins.elemAt segments 0);
    second = nixpkgs.lib.strings.toIntBase10 (builtins.elemAt segments 1);
  in
    (first == 10) ||
    (first == 172 && (second >= 16 && second <= 31)) ||
    (first == 192 && second == 168));

  isPrivateIPv6 = (ip:
    (nixpkgs.lib.strings.hasPrefix "fd" ip) ||
    (nixpkgs.lib.strings.hasPrefix "fc" ip));

  isIPv6 = nixpkgs.lib.strings.hasInfix ":";

  removeIPCidr = (ip: builtins.elemAt (nixpkgs.lib.strings.splitString "/" ip) 0);
in
{
  mkShortHash = mkShortHash;
  mkHash8 = mkShortHash 8;

  isPrivateIP = (ip: if (isIPv6 ip) then (isPrivateIPv6 ip) else (isPrivateIPv4 ip));

  isIPv6 = isIPv6;
  isIPv4 = (ip: !isIPv6 ip);

  removeIPCidr = removeIPCidr;
  addHostCidr = (ipRaw: let
    ip = removeIPCidr ipRaw;
  in if (isIPv6 ip) then "${ip}/128" else "${ip}/32");

  bracketIPv6 = (ip: if (isIPv6 ip) then "[${ip}]" else ip);
}
