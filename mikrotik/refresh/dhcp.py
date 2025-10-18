from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR, mtik_path, get_ipv4_netname

FILENAME = mtik_path("scripts/gen-dhcp.rsc")

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
