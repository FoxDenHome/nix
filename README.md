# FoxDen Homelab Nix configuration

## Goals (MVP)

- [ ] Set up basic NixOS machine template
	- [x] Kernel with module signing, ZFS and signed UKI
	- [x] Usage of pre-existing SB keys (so we can re-use)
- [ ] Set up simple basic app/group with veth NIC
- [ ] Port all apps from FoxDenHome/docker
- [ ] Samba server
- [ ] Kanidm auth
- [ ] All server machines should be fully NixOS
	- [ ] bengalfox
	- [ ] islandfox
	- [ ] icefox

## Goals (Post-MVP)

- [ ] Set up config for SR-IOV NIC

## Notes

zfs must be mountpoint=legacy

```sh
# Cleanup
nix-collect-garbage --delete-old
/run/current-system/bin/switch-to-configuration boot
# Update
nix flake update --flake 'github:FoxDenHome/nix'
nixos-rebuild switch --flake "github:FoxDenHome/nix#$(hostname)"
# Optionl: For update
export GITHUB_TOKEN='github_pat_.......'
export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
```
