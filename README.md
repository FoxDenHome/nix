# FoxDen core configuration

## TODO

- [ ] Firewall management (on router)
- [ ] DHCPv6 lease management (on router)
- [ ] apcupsd fails startup on boot, likely too early. just add better restart logic
- icefox
	- [ ] sanoid
- bengalfox
	- [ ] sanoid
	- [ ] syncoid
	- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)
	- [ ] ollama
	- [ ] hashtopolis
		- [x] mysql
		- [ ] backend
	- [ ] hashtopolis-agent
	- [ ] owncast
- islandfox
	- git
		- [ ] mysql (right now on sqlite3)
	- monitoring
		- grafana
			- [ ] manage more declaratively
			- [ ] mysql (right now on sqlite3)
	- SpaceAge
		- gmod
			- [ ] Make StarLord + SteamCMD a flake, too
	- [ ] affine
- [ ] Dedupe CNAME records better

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes
