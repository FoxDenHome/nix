#!/usr/bin/env python3

import re
from subprocess import check_output
from json import loads as json_loads
from urllib.parse import urlparse, parse_qs

FILENAME = "scripts/dyndns-update.rsc"
ROUTERS = ["router.foxden.network", "router-backup.foxden.network"]

_tofu_output_value = None
def load_tofu_output():
    global _tofu_output_value
    if _tofu_output_value is not None:
        return _tofu_output_value
    output = check_output(["tofu", "output", "-show-sensitive", "-json"], cwd="../terraform/domains").decode("utf-8")
    raw_output = json_loads(output)
    _tofu_output_value = raw_output["dynamic_urls"]["value"]
    return _tofu_output_value

def get_dyndns_url(host: str, record_type: str) -> str:
    val = load_tofu_output()
    for rec in val:
        rec_host = rec["name"] + "." + rec["zone"]
        if rec_host == host and rec["type"] == record_type:
            return urlparse(rec["url"])
    raise ValueError(f"No URL found for {host} {record_type}")

def get_dyndns_key(host: str, record_type: str) -> str:
    url = get_dyndns_url(host, record_type)
    qs = parse_qs(url.query)
    return qs["q"][0]

def replace_dyndns_url(host: str, record_type: str, line: str) -> str:
    key = get_dyndns_key(host, record_type)

    argname = "key6" if record_type == "AAAA" else "key"
    return re.sub(fr"{argname}=\"[^\"]+\"", f"{argname}=\"{key}\"", line)

def fix_script():
    with open(FILENAME, "r") as file:
        lines = file.readlines()
    
    for i, line in enumerate(lines):
        if "$dyndnsUpdate host=\"" not in line:
            continue

        m = re.match(r".*host=\"([^\"]+)\".*", line)
        host = m[1]

        if "key=\"" in line:
            line = replace_dyndns_url(host, "A", line)
        
        if "key6=\"" in line:
            line = replace_dyndns_url(host, "AAAA", line)
        
        lines[i] = line

    with open(FILENAME, "w") as file:
        file.writelines(lines)

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
    fix_script()
    for router in ROUTERS:
        print(f"## {router}")
        print_local_settings(router)
        print()
