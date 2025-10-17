from subprocess import check_call
from json import load as json_load
from os.path import join as path_join
from refresh.util import unlink_safe, NIX_DIR, mtik_path

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
    # TODO: Most of this
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dnsRecords.json"])
    with open("result", "r") as file:
        all_records = json_load(file)

    bind_conf = []

    zones = all_records["internal"]
    for zone in sorted(zones.keys()):
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

        with open(zone_file, "w") as out_file:
            out_file.write(data)

        bind_conf.append('zone "%s" IN {' % zone)
        bind_conf.append('    type native;')
        bind_conf.append('    file "/etc/pdns/%s.db";' % zone)
        bind_conf.append('};')

    with open(path_join(ZONE_DIR, "bind.conf"), "w") as out_file:
        out_file.write("\n".join(bind_conf) + "\n")
