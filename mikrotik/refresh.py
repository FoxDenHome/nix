#!/usr/bin/env python3

from refresh.dyndns import refresh_dyndns
from refresh.foxingress import refresh_foxingress

def main():
    #print("# DynDNS configuration")
    #refresh_dyndns()
    print("# foxIngress configuration")
    refresh_foxingress()


if __name__ == "__main__":
    main()
