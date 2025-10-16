# FoxDen core configuration

## TODO

- [ ] apcupsd fails startup on boot, likely too early. just add better restart logic
- [ ] Firewall management (on foxDen.hosts.gateway aka router)
- [ ] DNS management (on router)
- bengalfox
	- [ ] Set up config for SR-IOV NIC (hostDrivers/sriov.nix)
	- [ ] ollama
	- [ ] hashtopolis
		- [x] mysql
		- [ ] backend
	- [ ] hashtopolis-agent
	- [ ] owncast
	- [ ] sanoid
	- [ ] syncoid
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
- icefox
	- [ ] sanoid

## Notes

zfs must be mountpoint=legacy

DO NOT use /var/run, always use /run, or the entire OS explodes
