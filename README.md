# FoxDen Homelab Nix configuration

## Goals (MVP)

- [x] Set up basic NixOS machine template
	- [x] Kernel with module signing, ZFS and signed UKI
	- [x] Usage of pre-existing SB keys (so we can re-use)
- [x] Set up simple basic app/group with veth NIC
- [x] Kanidm auth
- [x] wireguard tunnel and VPN enforcement (systemd's RestrictNetworkInterfaces?)
- [x] HTTP(s) frontend service with OAuth toggle
	- [x] Basics
	- [x] OAuth
- [x] Samba server
- [ ] All server machines should be fully NixOS
	- [ ] bengalfox
		- [x] nas
			- [x] samba
			- [x] jellyfin
			- [x] nasweb
			- [x] deluge
		- [ ] kiwix
		- [ ] restic
		- [ ] mirror
		- [ ] gitbackup
		- [ ] e621dumper
		- [ ] fadumper
		- [ ] aurbuild
		- [ ] ollama
		- [ ] hashtopolis
		- [ ] hashtopolis-agent
		- [ ] owncast
	- [ ] islandfox
		- [ ] auth
		- [ ] scrypted
		- [ ] monitoring
		- [ ] syncthing
		- [ ] unifi-network
		- [ ] foxcaves
		- [ ] git
		- [ ] gitbackup
		- [ ] website
		- [ ] minecraft
		- [ ] darksignsonline
		- [ ] affine
	- [ ] icefox
		- [x] nas (see bengalfox)
		- [ ] gitbackup
		- [ ] syncthing
		- [ ] xmpp
		- [ ] mirror
		- [ ] snirouter
		- [ ] restic

## Goals (Post-MVP)

- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes
