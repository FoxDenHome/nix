from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR, mtik_path, get_ipv4_netname

FILENAME = mtik_path("scripts/gen-firewall.rsc")

def refresh_firewall():
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#firewall.json.router"])
    with open("result", "r") as file:
        firewall_rules = json_load(file)
    unlink_safe("result")

    header_lines = [
        "/ip/firewall/filter/remove [find dynamic=no]",
        "/ip/firewall/mangle/remove [find dynamic=no]",
        "/ip/firewall/nat/remove [find dynamic=no]",
        "/ipv6/firewall/filter/remove [find dynamic=no]",
        "/ipv6/firewall/mangle/remove [find dynamic=no]",
        "/ipv6/firewall/nat/remove [find dynamic=no]",
    ]
    lines = []
    for rule in firewall_rules:
        def optval(name: str, valname: str) -> str:
            val = rule.get(valname, "")
            return f' {name}={val}' if val else ''
        # add action=accept chain=lan-out-forward comment=Grafana dst-address=10.2.11.5 dst-port=80,443 protocol=tcp
        family = "ip" if rule["family"] == "ipv4" else "ipv6"
        chain = rule["chain"]
        if chain == "postrouting":
            chain = "srcnat"
        elif chain == "prerouting":
            chain = "dstnat"
        lines.append(f'/{family}/firewall/{rule["table"]}/add chain="{chain}" comment="{rule.get("comment","")}"{optval("dst-address", "destination")}{optval("dst-port", "dstport")}{optval("protocol", "protocol")}{optval("src-address", "source")}{optval("src-port", "srcport")}{optval("jump-target", "jumpTarget")} action={rule["action"]}')
    with open(FILENAME, "w") as file:
        file.write(("\n".join(header_lines + lines)) + "\n")
