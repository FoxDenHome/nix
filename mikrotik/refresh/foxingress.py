from subprocess import check_call
from json import load as json_load
from refresh.util import unlink_safe, NIX_DIR
from yaml import dump as yaml_dump

FILENAME = "files/foxingress/config.yml"

def refresh_foxingress():
    unlink_safe("result")
    check_call(["nix", "build", f"{NIX_DIR}#foxIngress.json.router"])
    with open("result", "r") as file:
        config = json_load(file)
    yaml_data = yaml_dump(config)
    with open(FILENAME, "w") as out_file:
        out_file.write(yaml_data)
