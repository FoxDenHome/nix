{ ... }:
let
  mkShortHash = (len: str:
    builtins.substring 0 len (builtins.hashString "sha256" str));
in
{
  mkShortHash = mkShortHash;
  mkHash8 = mkShortHash 8;
}
