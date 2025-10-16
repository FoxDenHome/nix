from os.path import dirname, realpath
from os import unlink

NIX_DIR = realpath(dirname(__file__) + "/../../nix")

def unlink_safe(path: str):
    try:
        unlink(path)
    except FileNotFoundError:
        pass
