#!/bin/sh
exec nix --show-trace --extra-experimental-features flakes repl .
