{ nixpkgs, ... }:
let
  types = nixpkgs.lib.types;

  validIpv4Segment = (s: let n = nixpkgs.lib.strings.toIntBase10 s; in n >= 0 && n <= 255);

  ipv4Check = (ip: let
    segments = nixpkgs.lib.strings.splitString "." ip;
    allValid = builtins.tryEval (nixpkgs.lib.lists.all validIpv4Segment segments);
  in
    allValid.success && allValid.value && (nixpkgs.lib.lists.length segments == 4));

  ipv6Check = (ip: let
      ipv6 = nixpkgs.lib.network.ipv6.fromString ip;
    in
    (builtins.tryEval ipv6).success);

  ipv6CidrCheck = (withCidr: ip: 
    (ipv6Check ip) && (withCidr == (nixpkgs.lib.strings.hasInfix "/" ip)));

  ipWithCidrCheck = (ipChecker: cidrMax: ipWithCidr: let
    segments = nixpkgs.lib.strings.splitString "/" ipWithCidr;
    ip = builtins.elemAt segments 0;
    cidr = nixpkgs.lib.strings.toIntBase10 (builtins.elemAt segments 1);
  in
    (nixpkgs.lib.lists.length segments == 2) && cidr >= 0 && cidr <= cidrMax && (ipChecker ip));

  ipv4WithoutCidr = types.addCheck types.str ipv4Check;
  ipv4WithCidr = types.addCheck types.str (ipWithCidrCheck ipv4Check 32);
  ipv6WithoutCidr = types.addCheck types.str (ipv6CidrCheck false);
  ipv6WithCidr = types.addCheck types.str (ipv6CidrCheck true);
  ipv4 = types.either ipv4WithoutCidr ipv4WithCidr;
  ipv6 = ipv6Check;
in
{
  ipv4WithoutCidr = ipv4WithoutCidr;
  ipv4WithCidr = ipv4WithCidr;
  ipv4 = ipv4;
  ipv6WithoutCidr = ipv6WithoutCidr;
  ipv6WithCidr = ipv6WithCidr;
  ipv6 = ipv6;

  ip = types.either ipv4 ipv6;
  ipWithCidr = types.either ipv4WithCidr ipv6WithCidr;
  ipWithoutCidr = types.either ipv4WithoutCidr types.ipv6WithoutCidr;
}
