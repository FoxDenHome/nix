/ip/firewall/filter
add action=accept chain=forward in-interface-list=zone-local out-interface-list=zone-wan
add action=accept chain=forward in-interface=oob
add action=accept chain=forward in-interface=wg-vpn
add action=accept chain=forward comment=foxDNS dst-port=53,9001 in-interface-list=zone-local out-interface=veth-dns protocol=tcp
add action=accept chain=forward comment=foxDNS dst-port=53 in-interface-list=zone-local out-interface=veth-dns protocol=udp
add action=accept chain=forward comment=foxIngress dst-port=80,443 out-interface=veth-foxingress protocol=tcp
add action=accept chain=forward comment=foxIngress dst-port=443 out-interface=veth-foxingress protocol=udp
add action=accept chain=forward comment=foxIngress dst-port=9001 in-interface-list=zone-local out-interface=veth-foxingress protocol=tcp
add action=reject chain=forward reject-with=icmp-admin-prohibited

/ipv6/firewall/filter
add action=accept chain=forward in-interface-list=zone-local out-interface-list=zone-wan
add action=accept chain=forward in-interface=oob
add action=accept chain=forward in-interface=wg-vpn
add action=accept chain=forward comment=foxDNS dst-port=53,9001 in-interface-list=zone-local out-interface=veth-dns protocol=tcp
add action=accept chain=forward comment=foxDNS dst-port=53 in-interface-list=zone-local out-interface=veth-dns protocol=udp
add action=accept chain=forward comment=foxIngress dst-port=80,443 out-interface=veth-foxingress protocol=tcp
add action=accept chain=forward comment=foxIngress dst-port=443 out-interface=veth-foxingress protocol=udp
add action=accept chain=forward comment=foxIngress dst-port=9001 in-interface-list=zone-local out-interface=veth-foxingress protocol=tcp
add action=reject chain=forward reject-with=icmp-admin-prohibited
