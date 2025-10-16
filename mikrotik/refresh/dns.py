from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR

def refresh_dns():
    # TODO: Most of this
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#dnsRecords.json"])
    with open("result", "r") as file:
        records = json_load(file)
