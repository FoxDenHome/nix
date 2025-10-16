#!/usr/bin/env python3

import re
from subprocess import check_output
from json import loads as json_loads
from urllib.parse import parse_qs, urlparse

FILENAME = "scripts/dyndns-update.rsc"
ROUTERS = ["router.foxden.network", "router-backup.foxden.network"]

SPECIAL_HOSTS = ROUTERS + [f"v4-{router}" for router in ROUTERS] + ["wan.foxden.network", "v4-wan.foxden.network"]

_dyndns_hosts_value = None
def load_dyndns_hosts():
    global _dyndns_hosts_value
    if _dyndns_hosts_value is not None:
        return _dyndns_hosts_value

    output = check_output(["tofu", "output", "-show-sensitive", "-json"], cwd="../terraform/domains").decode("utf-8")
    raw_output = json_loads(output)
    raw_value = raw_output["dynamic_urls"]["value"]

    value = {}
    for rec in raw_value:
        rec_host = rec["name"] + "." + rec["zone"]
        if rec["name"] == "@":
            rec_host = rec["zone"]

        if rec_host not in value:
            value[rec_host] = {}
        value[rec_host][rec["type"]] = rec
    _dyndns_hosts_value = value

    return _dyndns_hosts_value

def get_dyndns_url(host: str, record_type: str) -> str:
    val = load_dyndns_hosts()
    return urlparse(val[host][record_type]["url"])

def get_dyndns_key(host: str, record_type: str) -> str:
    url = get_dyndns_url(host, record_type)
    qs = parse_qs(url.query)
    return qs["q"][0]

def write_all_hosts(indent: str) -> list[str]:
    val = load_dyndns_hosts()
    lines = []
    for host in sorted(val.keys()):
        if host in SPECIAL_HOSTS:
            continue
        hostCfg = val[host]
        key4 = get_dyndns_key(host, "A")
        if "AAAA" in hostCfg:
            key6 = get_dyndns_key(host, "AAAA")
            ipv6 = hostCfg["AAAA"]["value"]
            lines.append(f'{indent}$dyndnsUpdate host="{host}" priv6addr={ipv6} key6="{key6}" key="{key4}" ip6addr=$ip6addr ipaddr=$ipaddr\n')
        else:
            lines.append(f'{indent}$dyndnsUpdate host="{host}" key="{key4}" ip6addr=$ip6addr ipaddr=$ipaddr\n')
    return lines

def write_script():
    with open(FILENAME, "r") as file:
        lines = file.readlines()
    
    outlines = []
    in_hosts = False
    found_hosts = False
    for line in lines:
        line_strip = line.strip()
        if in_hosts:
            if line_strip == "# END HOSTS":
                in_hosts = False
            else:
                continue
        outlines.append(line)
        if line_strip == "# BEGIN HOSTS":
            if found_hosts:
                raise RuntimeError("Multiple # BEGIN HOSTS found in script")
            indent = re.match(r"^(\s*)", line).group(1)
            in_hosts = True
            found_hosts = True
            outlines += write_all_hosts(indent)
            continue

    if not found_hosts:
        raise RuntimeError("No # BEGIN HOSTS found in script")

    with open(FILENAME, "w") as file:
        file.writelines(outlines)

#$dyndnsUpdate host=$DynDNSHost key=$DynDNSKey key6=$DynDNSKey6
#$dyndnsUpdate host=$DynDNSHost4 key=$DynDNSKey4 
#$dyndnsUpdate host=$DynDNSHostDNS key=$DynDNSKeyDNS key6=$DynDNSKeyDNS6
def print_local_settings(host: str):
    host_4 = f"v4-{host}"

    print(f":global DynDNSHost \"{host}\"")
    print(f":global DynDNSKey \"{get_dyndns_key(host, 'A')}\"")
    print(f":global DynDNSKey6 \"{get_dyndns_key(host, 'AAAA')}\"")

    print(f":global DynDNSHost4 \"{host_4}\"")
    print(f":global DynDNSKey4 \"{get_dyndns_key(host_4, 'A')}\"")

if __name__ == "__main__":
    write_script()
    for router in ROUTERS:
        print(f"## {router}")
        print_local_settings(router)
        print()
