# FoxDen core

## Machines

### bengalfox

- **Locator**: Rack; 2U, Supermicro chassis
- **CPU**: Dual Xeon E5-2690v4
- **RAM**: 256GB, DDR4-ECC, 2400 MT/s
- **Storage**:
	- nix: XFS: RAID1: 2 * 2TB NVMe SSD
	- zhdd: ZFS:
		- RAIDZ2: 8 * 18 TB SATA3 HDD
		- metadata special RAID1: 2 * 1TB SAS3 SSD (partition)
	- zssd: XFS: RAID1: 2 * 3TB SAS3 SSD (partition)
- **Network**: 25GbE (Mellanox ConnectX-6 Dx)

### islandfox

- **Locator**: Rack; Lenovo tiny mini-PC
- **CPU**: AMD Ryzen 7 PRO 470GE
- **RAM**: 64GB, DDR4, 3200 MT/s
- **Storage**:
	- nix: XFS: RAID1: 2TB NVMe SSD + 2TB SATA3 SSD
- **Network**: 1GbE

### icefox

- **Locator**: Hetzner
- **CPU**: AMD Ryzen 9 3900
- **RAM**: 128GB, DDR4, 2666 MT/s
- **Storage**:
	- nix: xfs: RAID1: 2 * 1TB NVMe SSD
	- ztank: ZFS:
		- RAIDZ2: 10 * 14 TB SATA3 HDD
- **Network**: 1GbE, no traffic limit

### redfox

- **Locator**: Vultr
- **CPU**: 1 vCPU "Intel high performance"
- **RAM**: 1GB
- **Storage**: vdisk 25 GB NVMe SSD
- **Network**: >= 1GbE, max 2 TB traffic

## TODO

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
