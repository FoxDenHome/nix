/ip/firewall/filter/remove [find dynamic=no]
/ip/firewall/mangle/remove [find dynamic=no]
/ip/firewall/nat/remove [find dynamic=no]
/ipv6/firewall/filter/remove [find dynamic=no]
/ipv6/firewall/mangle/remove [find dynamic=no]
/ipv6/firewall/nat/remove [find dynamic=no]
/system/script/run firewall-rules-snout
/ip/firewall/filter/add chain="forward" comment="auto-http-e621dumper-default" dst-address=10.3.10.12 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-e621dumper-default" dst-address=fd2c:f4cb:63be:3::a0c dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-e621dumper-default" dst-address=10.3.10.12 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-e621dumper-default" dst-address=fd2c:f4cb:63be:3::a0c dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-e621dumper-default" dst-address=10.3.10.12 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-e621dumper-default" dst-address=fd2c:f4cb:63be:3::a0c dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-fadumper-default" dst-address=10.3.10.13 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-fadumper-default" dst-address=fd2c:f4cb:63be:3::a0d dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-fadumper-default" dst-address=10.3.10.13 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-fadumper-default" dst-address=fd2c:f4cb:63be:3::a0d dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-fadumper-default" dst-address=10.3.10.13 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-fadumper-default" dst-address=fd2c:f4cb:63be:3::a0d dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-jellyfin-default" dst-address=10.2.11.3 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-jellyfin-default" dst-address=fd2c:f4cb:63be:2::b03 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-jellyfin-default" dst-address=10.2.11.3 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-jellyfin-default" dst-address=fd2c:f4cb:63be:2::b03 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-jellyfin-default" dst-address=10.2.11.3 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-jellyfin-default" dst-address=fd2c:f4cb:63be:2::b03 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-kiwix-default" dst-address=10.2.11.6 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-kiwix-default" dst-address=fd2c:f4cb:63be:2::b06 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-kiwix-default" dst-address=10.2.11.6 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-kiwix-default" dst-address=fd2c:f4cb:63be:2::b06 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-kiwix-default" dst-address=10.2.11.6 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-kiwix-default" dst-address=fd2c:f4cb:63be:2::b06 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-mirror-default" dst-address=10.3.10.11 dst-port=81 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-mirror-default" dst-address=fd2c:f4cb:63be:3::a0b dst-port=81 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-mirror-default" dst-address=10.3.10.11 dst-port=444 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-mirror-default" dst-address=fd2c:f4cb:63be:3::a0b dst-port=444 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-mirror-default" dst-address=10.3.10.11 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-mirror-default" dst-address=fd2c:f4cb:63be:3::a0b dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-nas-default" dst-address=10.2.11.1 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-nas-default" dst-address=fd2c:f4cb:63be:2::b01 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-nas-default" dst-address=10.2.11.1 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-nas-default" dst-address=fd2c:f4cb:63be:2::b01 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-nas-default" dst-address=10.2.11.1 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-nas-default" dst-address=fd2c:f4cb:63be:2::b01 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-restic-default" dst-address=10.2.11.12 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-restic-default" dst-address=fd2c:f4cb:63be:2::b0c dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-restic-default" dst-address=10.2.11.12 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-restic-default" dst-address=fd2c:f4cb:63be:2::b0c dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-restic-default" dst-address=10.2.11.12 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-restic-default" dst-address=fd2c:f4cb:63be:2::b0c dst-port=443 protocol=udp action=accept
/ip/firewall/nat/add chain="port-forward" comment="portforward-minecraft-default" dst-port=25565 protocol=tcp to-addresses=10.3.10.8 action=dst-nat
/ip/firewall/nat/add chain="port-forward" comment="portforward-spaceage-gmod-default" dst-port=27015 protocol=udp to-addresses=10.3.10.4 action=dst-nat
/ip/firewall/filter/add chain="forward" comment="auto-http-foxcaves-default" dst-address=10.3.10.1 dst-port=81 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-foxcaves-default" dst-address=fd2c:f4cb:63be:3::a01 dst-port=81 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-foxcaves-default" dst-address=10.3.10.1 dst-port=444 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-foxcaves-default" dst-address=fd2c:f4cb:63be:3::a01 dst-port=444 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-foxcaves-default" dst-address=10.3.10.1 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-foxcaves-default" dst-address=fd2c:f4cb:63be:3::a01 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-git-default" dst-address=10.3.10.2 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-git-default" dst-address=fd2c:f4cb:63be:3::a02 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-git-default" dst-address=10.3.10.2 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-git-default" dst-address=fd2c:f4cb:63be:3::a02 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-git-default" dst-address=10.3.10.2 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-git-default" dst-address=fd2c:f4cb:63be:3::a02 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-homeassistant-default" dst-address=10.2.12.2 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-homeassistant-default" dst-address=fd2c:f4cb:63be:2::c02 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-homeassistant-default" dst-address=10.2.12.2 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-homeassistant-default" dst-address=fd2c:f4cb:63be:2::c02 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-homeassistant-default" dst-address=10.2.12.2 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-homeassistant-default" dst-address=fd2c:f4cb:63be:2::c02 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="" dst-address=10.3.10.8 dst-port=25565 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="" dst-address=fd2c:f4cb:63be:3::a08 dst-port=25565 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-spaceage-api-default" dst-address=10.3.10.5 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-spaceage-api-default" dst-address=fd2c:f4cb:63be:3::a05 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-spaceage-api-default" dst-address=10.3.10.5 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-spaceage-api-default" dst-address=fd2c:f4cb:63be:3::a05 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-spaceage-api-default" dst-address=10.3.10.5 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-spaceage-api-default" dst-address=fd2c:f4cb:63be:3::a05 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="" dst-address=10.3.10.4 dst-port=27015 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="" dst-address=fd2c:f4cb:63be:3::a04 dst-port=27015 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-spaceage-tts-default" dst-address=10.3.10.6 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-spaceage-tts-default" dst-address=fd2c:f4cb:63be:3::a06 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-spaceage-tts-default" dst-address=10.3.10.6 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-spaceage-tts-default" dst-address=fd2c:f4cb:63be:3::a06 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-spaceage-tts-default" dst-address=10.3.10.6 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-spaceage-tts-default" dst-address=fd2c:f4cb:63be:3::a06 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-http-spaceage-website-default" dst-address=10.3.10.9 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-http-spaceage-website-default" dst-address=fd2c:f4cb:63be:3::a09 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-https-spaceage-website-default" dst-address=10.3.10.9 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-https-spaceage-website-default" dst-address=fd2c:f4cb:63be:3::a09 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="auto-quic-spaceage-website-default" dst-address=10.3.10.9 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="auto-quic-spaceage-website-default" dst-address=fd2c:f4cb:63be:3::a09 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-mgmt-unifi" dst-address=10.1.10.1 src-address=10.1.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-mgmt-unifi" dst-address=fd2c:f4cb:63be:1::a01 src-address=fd2c:f4cb:63be:1::/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-lan-unifi" dst-address=10.1.10.1 src-address=10.2.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-lan-unifi" dst-address=fd2c:f4cb:63be:1::a01 src-address=fd2c:f4cb:63be:2::/16 action=accept
/ip/firewall/filter/add chain="forward" comment="telegraf-allow-snmp" dst-port=161 protocol=udp src-address=10.2.11.21 action=accept
/ipv6/firewall/filter/add chain="forward" comment="telegraf-allow-snmp" dst-port=161 protocol=udp src-address=fd2c:f4cb:63be:2::b15 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-mgmt-bambu-x1" dst-address=10.4.10.1 src-address=10.1.0.0/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-lan-bambu-x1" dst-address=10.4.10.1 src-address=10.2.0.0/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-mgmt-nvr" dst-address=10.5.10.1 src-address=10.1.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-mgmt-nvr" dst-address=fd2c:f4cb:63be:5::0a01 src-address=fd2c:f4cb:63be:1::/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-lan-nvr" dst-address=10.5.10.1 src-address=10.2.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-lan-nvr" dst-address=fd2c:f4cb:63be:5::0a01 src-address=fd2c:f4cb:63be:2::/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-mgmt-s2s-network" dst-address=10.99.0.0/16 src-address=10.1.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-mgmt-s2s-network" dst-address=fd2c:f4cb:63be::a64:0/112 src-address=fd2c:f4cb:63be:1::/16 action=accept
/ip/firewall/filter/add chain="forward" comment="trusted-lan-s2s-network" dst-address=10.99.0.0/16 src-address=10.2.0.0/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="trusted-lan-s2s-network" dst-address=fd2c:f4cb:63be::a64:0/112 src-address=fd2c:f4cb:63be:2::/16 action=accept
/system/script/run firewall-rules-tail
