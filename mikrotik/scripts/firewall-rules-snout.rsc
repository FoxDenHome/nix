/ip/firewall/filter
add action=reject chain=forward comment=invalid connection-state=invalid reject-with=icmp-admin-prohibited
add action=fasttrack-connection chain=forward comment="related, established" connection-state=established,related hw-offload=yes
add action=accept chain=forward comment="related, established" connection-state=established,related
add action=accept chain=forward comment="dstnat'd" connection-nat-state=dstnat
add action=accept chain=forward protocol=icmp

/ipv6/firewall/filter
add action=reject chain=forward comment=invalid connection-state=invalid reject-with=icmp-admin-prohibited
add action=fasttrack-connection chain=forward comment="related, established" connection-state=established,related hw-offload=yes
add action=accept chain=forward comment="related, established" connection-state=established,related
add action=accept chain=forward protocol=icmpv6

/ip/firewall/nat
add action=endpoint-independent-nat chain=srcnat disabled=yes out-interface=wan protocol=udp randomise-ports=yes
add action=masquerade chain=srcnat comment=WAN out-interface=wan
add action=masquerade chain=srcnat comment=cghmn dst-address=!100.96.41.0/24 out-interface-list=iface-cghmn src-address=!100.96.41.0/24
add action=masquerade chain=srcnat disabled=yes out-interface=wg-s2s
add action=masquerade chain=srcnat comment=Container src-address=172.17.0.0/16
add action=jump chain=dstnat comment=Hairpin dst-address=50.47.251.45 jump-target=port-forward
add action=jump chain=dstnat comment="Hairpin fallback" dst-address=50.123.106.178 jump-target=port-forward
add action=jump chain=dstnat comment="Local forward" dst-address-list=local-ip in-interface-list=zone-local jump-target=local-port-forward
add action=jump chain=dstnat comment=External in-interface-list=zone-wan jump-target=port-forward
add action=dst-nat chain=local-port-forward comment="DNS TCP" dst-port=53 protocol=tcp to-addresses=172.17.2.2
add action=dst-nat chain=local-port-forward comment="DNS UDP" dst-port=53 protocol=udp to-addresses=172.17.2.2
add action=dst-nat chain=local-port-forward comment="foxIngress Prometheus" dst-port=5303 protocol=tcp to-addresses=172.17.0.2 to-ports=9001
add action=dst-nat chain=port-forward comment="HTTP(S)" dst-port=80,443 protocol=tcp to-addresses=172.17.0.2
add action=dst-nat chain=port-forward comment=QUIC dst-port=443 protocol=udp to-addresses=172.17.0.2

/ipv6/firewall/nat
add action=jump chain=dstnat comment="Local forward" dst-address-list=local-ip in-interface-list=zone-local jump-target=local-port-forward
add action=src-nat chain=srcnat comment="VPN Masq" dst-address=!fd2c:f4cb:63be::/60 in-interface=wg-vpn to-address=2a0e:7d44:f069:a00::a64:ffff/128
add action=netmap chain=dstnat comment="Ingress PT" dst-address=2a0e:7d44:f069:a00::/60 to-address=fd2c:f4cb:63be::/60
add action=netmap chain=srcnat comment="Egress PT" dst-address=!fd2c:f4cb:63be::/60 in-interface-list=zone-local src-address=fd2c:f4cb:63be::/60 to-address=2a0e:7d44:f069:a00::/60
add action=dst-nat chain=local-port-forward comment="DNS TCP" dst-port=53 protocol=tcp to-address=fd2c:f4cb:63be::ac11:202/128 to-ports=53
add action=dst-nat chain=local-port-forward comment="DNS UDP" dst-port=53 protocol=udp to-address=fd2c:f4cb:63be::ac11:202/128 to-ports=53
add action=dst-nat chain=local-port-forward comment="foxIngress Prometheus" dst-port=5303 protocol=tcp to-address=fd2c:f4cb:63be::ac11:2/128 to-ports=9001
