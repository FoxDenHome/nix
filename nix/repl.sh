#!/bin/sh
A="${1#.}"
exec nix --show-trace --extra-experimental-features flakes repl "$A"
