:local topdomain

:set topdomain "foxden.network"

:put "Adjusting lease times"
/ip/dhcp-server/lease set [/ip/dhcp-server/lease find dynamic=no] lease-time=1d

:put "Appending zone file 10.in-addr.arpa"

:local loadscript ":put \"\\\$TTL 300\"
:for i from=1 to=9 do={ 
    :put \"1.0.\$i IN PTR gateway.foxden.network.\"
    :put \"53.0.\$i IN PTR dns.foxden.network.\"
    :put \"123.0.\$i IN PTR ntp.foxden.network.\"
    :put \"1.1.\$i IN PTR router.foxden.network.\"
    :put \"2.1.\$i IN PTR router-backup.foxden.network.\"
    :put \"123.1.\$i IN PTR ntpi.foxden.network.\"
}"

:execute script=$loadscript file=pdns/10.in-addr.arpa.txt

:put "Appending zone file 0.0.0.e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa"

:local loadscript ":put \"\\\$TTL 300\"
:for i from=1 to=9 do={
    :put \"1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR gateway.foxden.network.\"
    :put \"5.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR dns.foxden.network.\"
    :put \"b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR ntp.foxden.network.\"
    :put \"1.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR router.foxden.network.\"
    :put \"2.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR router-backup.foxden.network.\"
    :put \"b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i.0.0.0 IN PTR ntpi.foxden.network.\"
}"

:execute script=$loadscript file=pdns/e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa.txt

:put Done
:do {
    /file/add name=container-restart-all
} on-error={}
