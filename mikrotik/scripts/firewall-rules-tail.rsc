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

add action=accept chain=input connection-state=established,related
add action=accept chain=input protocol=ipv6-encap
add action=accept chain=input protocol=icmp
add action=accept chain=input comment="HTTP(S)" dst-port=80,443 protocol=tcp
add action=accept chain=input comment=BGP dst-port=179 protocol=tcp
add action=accept chain=input comment=WireGuard dst-port=13231-13232 protocol=udp
add action=accept chain=input in-interface=lo
add action=accept chain=input in-interface=oob
add action=accept chain=input in-interface-list=zone-local
add action=reject chain=input reject-with=icmp-admin-prohibited

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

add action=accept chain=input connection-state=established,related
add action=accept chain=input protocol=icmpv6
add action=accept chain=input comment="HTTP(S)" dst-port=80,443 protocol=tcp
add action=accept chain=input comment=BGP dst-port=179 protocol=tcp
add action=accept chain=input comment=WireGuard dst-port=13231-13232 protocol=udp
add action=accept chain=input in-interface=lo
add action=accept chain=input in-interface=oob
add action=accept chain=input in-interface-list=zone-local
add action=reject chain=input reject-with=icmp-admin-prohibited
