from subprocess import check_call
from json import load as json_load
from os.path import join as path_join
from refresh.util import unlink_safe, NIX_DIR, mtik_path

ZONE_DIR = mtik_path("files/pdns")

def refresh_pdns():
    # TODO: Most of this
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dnsRecords.json"])
    with open("result", "r") as file:
        all_records = json_load(file)

    zones = all_records["internal"]
    for zone in sorted(zones.keys()):
        records = zones[zone]
        zone_file = path_join(ZONE_DIR, f"{zone}.gen.db")

        lines = []
        for record in records:
            lines.append(f"{record['name']} {record['ttl']} IN {record['type']} {record['value']}")
        data = "\n".join(sorted(lines)) + "\n"

        with open(zone_file, "w") as out_file:
            out_file.write(data)
