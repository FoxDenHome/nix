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
		- [x] Pre migration
			- [x] nas
				- [x] samba
				- [x] jellyfin
				- [x] nasweb
				- [x] deluge
				- [x] nzbget
			- [x] e621dumper
			- [x] fadumper
			- [x] restic
			- [x] rest-server
			- [x] kiwix
			- [x] mirror
			- [x] gitbackup
			- [x] aurbuild
		- [ ] Post migration
			- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)
			- [ ] ollama
			- [ ] hashtopolis
				- [ ] mysql
				- [ ] backend
			- [ ] hashtopolis-agent
			- [ ] owncast
	- [ ] islandfox
		- [ ] Pre migration
			- [x] restic
			- [x] syncthing
			- [x] auth
			- [x] scrypted
			- [x] unifi-network
			- [ ] homeassistant VM
			- [ ] foxcaves
				- [ ] postgres
				- [ ] redis
				- [ ] site (OCI)
			- [x] gitbackup
			- [ ] website
			- [ ] monitoring
				- [ ] grafana
				- [ ] prometheus
				- [ ] telegraf
				- [ ] mktxp
			- [ ] git
			- [ ] minecraft
			- [ ] SpaceAge
			- [ ] DarkSignsOnline
		- [ ] Post migration
			- [ ] affine
	- [ ] icefox
		- [ ] Pre migration
			- [x] nas (see bengalfox)
			- [x] restic
			- [x] rest-server
			- [x] kiwix
			- [x] mirror
			- [x] gitbackup
			- [x] syncthing
			- [ ] snirouter
			- [ ] xmpp

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes

## TODO

- Swap subnet to 10.0.0.0/12 maybe?
