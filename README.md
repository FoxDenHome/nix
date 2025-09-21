# FoxDen Homelab Nix configuration

## Goals (MVP)

- [x] Set up basic NixOS machine template
	- [x] Kernel with module signing, ZFS and signed UKI
	- [x] Usage of pre-existing SB keys (so we can re-use)
- [x] Set up simple basic app/group with veth NIC
- [x] Kanidm auth
- [ ] wireguard tunnel and VPN enforcement (systemd's RestrictNetworkInterfaces?)
- [ ] HTTP(s) frontend service with OAuth toggle
	- [x] Basics
	- [ ] OAuth
- [ ] Port all apps from FoxDenHome/docker
- [ ] Samba server
- [ ] All server machines should be fully NixOS
	- [ ] bengalfox
	- [ ] islandfox
	- [ ] icefox

## Goals (Post-MVP)

- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes
