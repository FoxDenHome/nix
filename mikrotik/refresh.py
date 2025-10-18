#!/usr/bin/env python3

from refresh.dyndns import refresh_dyndns
from refresh.foxingress import refresh_foxingress
from refresh.pdns import refresh_pdns
from refresh.dhcp import refresh_dhcp
from refresh.firewall import refresh_firewall

def main():
    #print("# DynDNS configuration")
    #refresh_dyndns()
    print("# foxIngress configuration")
    refresh_foxingress()
    print("# PowerDNS configuration")
    refresh_pdns()
    print("# DHCP configuration")
    refresh_dhcp()
    print("# Firewall configuration")
    refresh_firewall()


if __name__ == "__main__":
    main()
