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
- [x] Make daemon that syncs VM XMLs and create initial VM QCOW2 images automatically
- [ ] Systems
	- [ ] bengalfox
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
		- [x] win2k22 VM
		- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)
		- [ ] ollama
		- [ ] hashtopolis
			- [x] mysql
			- [ ] backend
		- [ ] hashtopolis-agent
		- [ ] owncast
	- [ ] islandfox
		- [x] restic
		- [x] syncthing
		- [x] auth
		- [x] scrypted
		- [x] unifi-network
		- [x] homeassistant VM (QEMU setup done, import after migration!)
		- [x] gitbackup
		- [x] DarkSignsOnline
		- [x] foxcaves
			- [x] postgres
			- [x] redis
			- [x] site (OCI)
		- [x] website
		- [x] minecraft
			- [x] turn into a flake built from server JAR + Collar mod + custom start.sh
		- [x] git
			- [ ] mysql (right now on sqlite3)
		- [x] monitoring
			- [x] grafana
			- [x] prometheus
			- [x] telegraf
			- [x] mktxp
			- [x] grafana
				- [ ] manage more declaratively
				- [ ] mysql (right now on sqlite3)
		- [x] SpaceAge
			- [x] mysql
			- [x] tts
			- [x] api
				- [x] Move CORS header emission into app itself?
			- [x] gmod (OCI)
				- [ ] Make StarLord + SteamCMD a flake, too
			- [x] website
		- [ ] affine
	- [ ] icefox
		- [x] nas (see bengalfox)
		- [x] restic
		- [x] rest-server
		- [x] kiwix
		- [x] mirror
		- [x] gitbackup
		- [x] syncthing
		- [ ] snirouter
		- [ ] xmpp
		- [ ] arcticfox

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes

## TODO

- Swap subnet to 10.0.0.0/12 maybe?
