/ip/firewall/filter/remove [find dynamic=no]
/ip/firewall/mangle/remove [find dynamic=no]
/ip/firewall/nat/remove [find dynamic=no]
/ipv6/firewall/filter/remove [find dynamic=no]
/ipv6/firewall/mangle/remove [find dynamic=no]
/ipv6/firewall/nat/remove [find dynamic=no]
/ip/firewall/nat/add chain="srcnat" comment="" dst-address=!10.0.0.0/8 src-address=10.0.0.0/8 action=masquerade
/ipv6/firewall/nat/add chain="srcnat" comment="" dst-address=!10.0.0.0/8 src-address=10.0.0.0/8 action=masquerade
/ip/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=10.3.10.12 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=fd2c:f4cb:63be:3::a0c dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=10.3.10.12 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=fd2c:f4cb:63be:3::a0c dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=10.3.10.12 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-e621dumper" dst-address=fd2c:f4cb:63be:3::a0c dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=10.3.10.13 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=fd2c:f4cb:63be:3::a0d dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=10.3.10.13 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=fd2c:f4cb:63be:3::a0d dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=10.3.10.13 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-fadumper" dst-address=fd2c:f4cb:63be:3::a0d dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=10.2.11.3 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=fd2c:f4cb:63be:2::b03 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=10.2.11.3 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=fd2c:f4cb:63be:2::b03 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=10.2.11.3 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-jellyfin" dst-address=fd2c:f4cb:63be:2::b03 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=10.2.11.6 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=fd2c:f4cb:63be:2::b06 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=10.2.11.6 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=fd2c:f4cb:63be:2::b06 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=10.2.11.6 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-kiwix" dst-address=fd2c:f4cb:63be:2::b06 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-mirror" dst-address=10.3.10.11 dst-port=81 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-mirror" dst-address=fd2c:f4cb:63be:3::a0b dst-port=81 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-mirror" dst-address=10.3.10.11 dst-port=444 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-mirror" dst-address=fd2c:f4cb:63be:3::a0b dst-port=444 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-mirror" dst-address=10.3.10.11 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-mirror" dst-address=fd2c:f4cb:63be:3::a0b dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-nas" dst-address=10.2.11.1 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-nas" dst-address=fd2c:f4cb:63be:2::b01 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-nas" dst-address=10.2.11.1 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-nas" dst-address=fd2c:f4cb:63be:2::b01 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-nas" dst-address=10.2.11.1 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-nas" dst-address=fd2c:f4cb:63be:2::b01 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-restic" dst-address=10.2.11.12 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-restic" dst-address=fd2c:f4cb:63be:2::b0c dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-restic" dst-address=10.2.11.12 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-restic" dst-address=fd2c:f4cb:63be:2::b0c dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-restic" dst-address=10.2.11.12 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-restic" dst-address=fd2c:f4cb:63be:2::b0c dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=10.3.10.1 dst-port=81 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=fd2c:f4cb:63be:3::a01 dst-port=81 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=10.3.10.1 dst-port=444 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=fd2c:f4cb:63be:3::a01 dst-port=444 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=10.3.10.1 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-foxcaves" dst-address=fd2c:f4cb:63be:3::a01 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-git" dst-address=10.3.10.2 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-git" dst-address=fd2c:f4cb:63be:3::a02 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-git" dst-address=10.3.10.2 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-git" dst-address=fd2c:f4cb:63be:3::a02 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-git" dst-address=10.3.10.2 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-git" dst-address=fd2c:f4cb:63be:3::a02 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=10.2.12.2 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=fd2c:f4cb:63be:2::c02 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=10.2.12.2 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=fd2c:f4cb:63be:2::c02 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=10.2.12.2 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-homeassistant" dst-address=fd2c:f4cb:63be:2::c02 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=10.3.10.5 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=fd2c:f4cb:63be:3::a05 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=10.3.10.5 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=fd2c:f4cb:63be:3::a05 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=10.3.10.5 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-api" dst-address=fd2c:f4cb:63be:3::a05 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=10.3.10.6 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=fd2c:f4cb:63be:3::a06 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=10.3.10.6 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=fd2c:f4cb:63be:3::a06 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=10.3.10.6 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-tts" dst-address=fd2c:f4cb:63be:3::a06 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=10.3.10.9 dst-port=80 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=fd2c:f4cb:63be:3::a09 dst-port=80 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=10.3.10.9 dst-port=443 protocol=tcp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=fd2c:f4cb:63be:3::a09 dst-port=443 protocol=tcp action=accept
/ip/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=10.3.10.9 dst-port=443 protocol=udp action=accept
/ipv6/firewall/filter/add chain="forward" comment="web-spaceage-website" dst-address=fd2c:f4cb:63be:3::a09 dst-port=443 protocol=udp action=accept
/ip/firewall/filter/add chain="forward" comment="" dst-port=161 protocol=udp src-address=10.2.11.21/16 action=accept
/ipv6/firewall/filter/add chain="forward" comment="" dst-port=161 protocol=udp src-address=fd2c:f4cb:63be:2::b15/64 action=accept
/ip/firewall/nat/add chain="srcnat" comment="" dst-address=!172.17.0.0/16 src-address=172.17.0.0/16 action=masquerade
/ipv6/firewall/nat/add chain="srcnat" comment="" dst-address=!172.17.0.0/16 src-address=172.17.0.0/16 action=masquerade
/ip/firewall/nat/add chain="dstnat" comment="Hairpin" dst-address=127.0.0.1 jump-target=port-forward action=jump
/ipv6/firewall/nat/add chain="dstnat" comment="Hairpin" dst-address=127.0.0.1 jump-target=port-forward action=jump
/ip/firewall/nat/add chain="dstnat" comment="Hairpin fallback" dst-address=127.0.0.2 jump-target=port-forward action=jump
/ipv6/firewall/nat/add chain="dstnat" comment="Hairpin fallback" dst-address=127.0.0.2 jump-target=port-forward action=jump
