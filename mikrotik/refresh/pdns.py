from subprocess import check_call
from json import load as json_load
from os.path import join as path_join
from refresh.util import unlink_safe, NIX_DIR, mtik_path
from yaml import safe_load as yaml_load, dump as yaml_dump

ZONE_DIR = mtik_path("files/pdns")

SPECIAL_ZONES = {}

def foreach_vlan(records: list[str]) -> list[str]:
    lines = []
    for vlan in range(0, 10):
        for record in records:
            lines.append(record % vlan)
    return lines

SPECIAL_ZONES["foxden.network"] = lambda: [
    "$INCLUDE /etc/pdns/foxden.network.local.db"
    "ns1 IN A 10.2.0.53"
    "ns2 IN A 10.2.0.53"
    "ns3 IN A 10.2.0.53"
    "ns4 IN A 10.2.0.53"
]

SPECIAL_ZONES["10.in-addr.arpa"] = lambda: foreach_vlan([
    "1.0.%d IN PTR gateway.foxden.network.",
    "53.0.%d IN PTR dns.foxden.network.",
    "123.0.%d IN PTR ntp.foxden.network.",
    "1.1.%d IN PTR router.foxden.network.",
    "2.1.%d IN PTR router-backup.foxden.network.",
    "123.1.%d IN PTR ntpi.foxden.network.",
])

SPECIAL_ZONES["e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa"] = lambda: foreach_vlan([
    "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR gateway.foxden.network.",
    "5.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR dns.foxden.network.",
    "b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR ntp.foxden.network.",
    "1.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR router.foxden.network.",
    "2.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR router-backup.foxden.network.",
    "b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.%x.0.0.0 IN PTR ntpi.foxden.network.",
])

"""zone "%s" IN {
    type native;
    file "/etc/pdns/%s.db";
};"""

def refresh_pdns():
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dnsRecords.json"])
    with open("result", "r") as file:
        all_records = json_load(file)
    unlink_safe("result")

    bind_conf = []

    print("## Reading recursor-template.conf")
    with open(path_join(ZONE_DIR, "recursor-template.conf"), "r") as file:
        recursor_data = yaml_load(file)

    if "forward_zones" not in recursor_data:
        recursor_data["forward_zones"] = []

    print("## Writing zone files")
    zones = all_records["internal"]
    for zone in sorted(zones.keys()):
        print(f"### Processing zone {zone}")
        records = zones[zone]
        zone_file = path_join(ZONE_DIR, f"{zone}.db")

        fixed_lines = [
            "$TTL 300",
            "$INCLUDE /etc/pdns/authority.db"
        ]

        if zone in SPECIAL_ZONES:
            fixed_lines += SPECIAL_ZONES[zone]()

        lines = []
        for record in records:
            lines.append(f"{record['name']} {record['ttl']} IN {record['type']} {record['value']}")
        data = "\n".join(fixed_lines + sorted(lines)) + "\n"

        with open(zone_file, "w") as file:
            file.write(data)

        bind_conf.append('zone "%s" IN {' % zone)
        bind_conf.append('    type native;')
        bind_conf.append('    file "/etc/pdns/%s.db";' % zone)
        bind_conf.append('};')

        recursor_data["forward_zones"].append({
            "zone": zone,
            "forwarders": ["127.0.0.1:530"]
        })

    print("## Writing bind.conf")
    with open(path_join(ZONE_DIR, "bind.conf"), "w") as file:
        file.write("\n".join(bind_conf) + "\n")

    print("## Writing recursor.conf")
    with open(path_join(ZONE_DIR, "recursor.conf"), "w") as file:
        yaml_dump(recursor_data, file)
