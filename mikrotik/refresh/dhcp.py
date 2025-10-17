# add address=10.3.10.6 comment=spaceage-tts lease-time=1d mac-address=62:BF:FB:E4:89:51 server=dhcp-dmz

from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR, mtik_path, get_ipv4_netname

FILENAME = mtik_path("scripts/dhcp-leases-reload.rsc")

def refresh_dhcpv4(dhcp_leases):
    lines = []
    lines.append("/ip/dhcp-server/lease/remove [find dynamic=no]")
    for lease in dhcp_leases:
        if "ipv4" in lease:
            netname = get_ipv4_netname(lease["ipv4"])
            lines.append(f'/ip/dhcp-server/lease/add address={lease["ipv4"]} comment="{lease["name"]}" lease-time=1d mac-address={lease["mac"]} server=dhcp-{netname}')
    with open(FILENAME, "w") as file:
        file.write("\n".join(lines) + "\n")

def refresh_dhcp():
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dhcp.json.router"])
    with open("result", "r") as file:
        dhcp_leases = json_load(file)
    unlink_safe("result")

    header_lines = [
        "/ip/dhcp-server/lease/remove [find dynamic=no]"
    ]
    lines = []
    for lease in dhcp_leases:
        if "ipv4" in lease:
            netname = get_ipv4_netname(lease["ipv4"])
            lines.append(f'/ip/dhcp-server/lease/add mac-address={lease["mac"]} address={lease["ipv4"]} comment="{lease["name"]}" lease-time=1d server=dhcp-{netname}')
    with open(FILENAME, "w") as file:
        file.write(("\n".join(header_lines + sorted(lines))) + "\n")
