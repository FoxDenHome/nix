# add address=10.3.10.6 comment=spaceage-tts lease-time=1d mac-address=62:BF:FB:E4:89:51 server=dhcp-dmz

from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR, mtik_path, get_ipv4_netname

FILENAME = mtik_path("scripts/dhcp-leases.rsc")

def refresh_pdns():
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dnsRecords.json"])
    with open("result", "r") as file:
        all_records = json_load(file)
    unlink_safe("result")
