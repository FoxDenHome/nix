:local topdomain

:set topdomain "foxden.network"

:put "Adjusting lease times"
/ip/dhcp-server/lease set [/ip/dhcp-server/lease find dynamic=no] lease-time=1d

:put "Appending zone file foxden.network"

:local loadscript ":put \"\\\$TTL 300\"
:foreach i in=[/ip/dhcp-server/lease/find comment dynamic=no] do={
    :local dhcpent [/ip/dhcp-server/lease/get \$i]
    :local hostshort (\$dhcpent->\"comment\")

    :if (\$hostshort != \"ntp\" && \$hostshort != \"dns\" && \$hostshort != \"gateway\") do={
      :put (\$hostshort . \" IN A \" . (\$dhcpent->\"address\"))
    }
}

:foreach i in=[/ipv6/dhcp-server/binding/find comment dynamic=no] do={
    :local dhcpent [/ipv6/dhcp-server/binding/get \$i]
    :local hostshort (\$dhcpent->\"comment\")

    :if (\$hostshort != \"ntp\" && \$hostshort != \"dns\" && \$hostshort != \"gateway\") do={
      :local sanaddr ([:deserialize value=(\$dhcpent->\"address\") from=dsv delimiter=\"/\" options=dsv.plain]->0->0)
      :put (\$hostshort . \" IN AAAA \" . \$sanaddr)
    }
}"

:execute script=$loadscript file=pdns/foxden.network.txt

:put "Appending zone file 10.in-addr.arpa"

:local loadscript ":put \"\\\$TTL 300\"
:for i from=1 to=9 do={ 
    :put \"1.0.\$i IN PTR gateway.foxden.network.\"
    :put \"53.0.\$i IN PTR dns.foxden.network.\"
    :put \"123.0.\$i IN PTR ntp.foxden.network.\"
    :put \"1.1.\$i IN PTR router.foxden.network.\"
    :put \"2.1.\$i IN PTR router-backup.foxden.network.\"
    :put \"123.1.\$i IN PTR ntpi.foxden.network.\"
}
:foreach i in=[/ip/dhcp-server/lease/find comment dynamic=no] do={
    :local dhcpent [/ip/dhcp-server/lease/get \$i]
    :local hostshort (\$dhcpent->\"comment\")

    :if (\$hostshort != \"ntp\" && \$hostshort != \"dns\" && \$hostshort != \"gateway\") do={
      :local hostname (\$hostshort . \".$topdomain.\")
      :local ipNum [ :tonum [ :toip (\$dhcpent->\"address\") ] ]
      :if (((\$ipNum >> 24) & 255) = 10) do={
        :local reverseIpString ((\$ipNum & 255) . \".\" . ((\$ipNum >> 8) & 255) . \".\" . ((\$ipNum >> 16) & 255))
        :put (\$reverseIpString . \" IN PTR \" . \$hostname)
      }
    }
}"

:execute script=$loadscript file=pdns/10.in-addr.arpa.txt

:put "Appending zone file 41.96.100.in-addr.arpa"

:local loadscript ":put \"\\\$TTL 300\"
  :put \"1 IN PTR router.foxden.network.\"
  :put \"2 IN PTR router-backup.foxden.network.\"
  :put \"53 IN PTR dns.foxden.network.\"
  :put \"123 IN PTR ntp.foxden.network.\"
:foreach i in=[/ip/dhcp-server/lease/find comment dynamic=no] do={
    :local dhcpent [/ip/dhcp-server/lease/get \$i]
    :local hostshort (\$dhcpent->\"comment\")

    :if (\$hostshort != \"ntp\" && \$hostshort != \"dns\" && \$hostshort != \"gateway\") do={
      :local hostname (\$hostshort . \".$topdomain.\")
      :local ipNum [ :tonum [ :toip (\$dhcpent->\"address\") ] ]
      :if (((\$ipNum >> 24) & 255) = 100 && ((\$ipNum >> 16) & 255) = 96 && ((\$ipNum >> 8) & 255) = 41) do={
        :local reverseIpString (\$ipNum & 255)
        :put (\$reverseIpString . \" IN PTR \" . \$hostname)
      }
    }
}"

:execute script=$loadscript file=pdns/41.96.100.in-addr.arpa.txt

:put "Appending zone file 0.0.0.e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa"

:local loadscript ":put \"\\\$TTL 300\"
:for i from=1 to=9 do={
    :put \"1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR gateway.foxden.network.\"
    :put \"5.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR dns.foxden.network.\"
    :put \"b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR ntp.foxden.network.\"
    :put \"1.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR router.foxden.network.\"
    :put \"2.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR router-backup.foxden.network.\"
    :put \"b.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.\$i IN PTR ntpi.foxden.network.\"
}
:foreach i in=[/ipv6/dhcp-server/binding/find comment dynamic=no] do={
    :local dhcpent [/ipv6/dhcp-server/binding/get \$i]
    :local hostshort (\$dhcpent->\"comment\")

    :if (\$hostshort != \"ntp\" && \$hostshort != \"dns\" && \$hostshort != \"gateway\") do={
      :local hostname (\$hostshort . \".$topdomain.\")
      :local sanaddr ([:deserialize value=(\$dhcpent->\"address\") from=dsv delimiter=\"/\" options=dsv.plain]->0->0)
    }
}"

:execute script=$loadscript file=pdns/0.0.0.e.b.3.6.b.c.4.f.c.2.d.f.ip6.arpa.txt

:put Done
:do {
    /file/add name=container-restart-all
} on-error={}
