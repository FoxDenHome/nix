# FoxDen Homelab Nix configuration

## Goals

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
- [x] OpenSearch with authentication
- [ ] Systems
	- [ ] bengalfox
		- [ ] Pre migration
			- [x] nas
				- [x] samba
				- [x] jellyfin
				- [x] nasweb
				- [x] deluge (TO DO: declarative config + mounts)
			- [x] e621dumper
			- [x] fadumper
			- [x] restic
			- [ ] rest-server
			- [ ] kiwix
			- [ ] mirror
			- [ ] gitbackup
			- [ ] aurbuild
		- [ ] Post migration
			- [ ] ollama
			- [ ] hashtopolis
			- [ ] hashtopolis-agent
			- [ ] owncast
			- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)
			- [ ] nas
				- [ ] nzbget
	- [ ] islandfox
		- [ ] Pre migration
			- [ ] restic
			- [ ] auth
			- [ ] scrypted
			- [ ] monitoring
			- [ ] syncthing
			- [ ] unifi-network
			- [ ] homeassistant VM
			- [ ] foxcaves
			- [ ] git
			- [ ] gitbackup
			- [ ] website
			- [ ] minecraft
			- [ ] darksignsonline
			- [ ] SpaceAge
		- [ ] Post migration
			- [ ] affine
	- [ ] icefox
		- [ ] Pre migration
			- [x] nas (see bengalfox)
			- [ ] restic
			- [ ] gitbackup
			- [ ] syncthing
			- [ ] xmpp
			- [ ] mirror
			- [ ] snirouter

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes
