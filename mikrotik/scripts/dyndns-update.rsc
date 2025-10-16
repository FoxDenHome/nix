# dontrequireperms=yes
# policy=ftp,read,write,policy,test

:local ipaddrfind [ /ip/address/find interface=wan ]
:if ([:len $ipaddrfind] < 1) do={
    :log warning "No WAN IP address found"
    :exit
}
:local ipaddrcidr [/ip/address/get ($ipaddrfind->0) address]
:local ipaddr ([:deserialize value=$ipaddrcidr from=dsv delimiter="/" options=dsv.plain]->0->0)

:local ip6addrfind [ /ipv6/address/find interface=wan !(address in fe80::/64) !(address in fc00::/7) ]
:if ([:len $ip6addrfind] < 1) do={
    :log warning "No WAN IPv6 address found"
    :exit
}
:local ip6addrcidr [/ipv6/address/get ($ip6addrfind->0) address]
:local ip6addr ([:toip6 ([:deserialize value=$ip6addrcidr from=dsv delimiter="/" options=dsv.plain]->0->0)] & ffff:ffff:ffff:ffff:fff0::)

:global DynDNSHost
:global DynDNSHost4
:global DynDNSKey
:global DynDNSKey4
:global DynDNSKey6
:global DynDNSSuffix6
:global DynDNSHostDNS
:global DynDNSKeyDNS
:global DynDNSKeyDNS6

:local isprimary 0
#[ /interface/vrrp/get vrrp-mgmt-gateway master ]
:if ($DynDNSHost = "router.foxden.network") do={
    :set isprimary 1
}

/system/script/run firewall-update

:global dyndnsUpdateOne do={
    :global logputdebug
    :global logputinfo
    :global logputerror

    $logputdebug ("[DynDNS] Beginning update of $updatehost $host")
    :if ($dns!="") do={
        :delay 1s
        :do {
            :local dnsip [:resolve $host type=$dnstype server=$dns]
            if ($dnsip=$ipaddr) do={
                $logputdebug ("[DynDNS] No change in IP address for $updatehost $host is $ipaddr")
                :return ""
            }
        } on-error={
            $logputerror ("[DynDNS] Unable to resolve $host using $dns type $dnstype")
            :return ""
        }
    }

    :delay 5s

    :do {
        :local result [/tool/fetch mode=$mode http-auth-scheme=basic url="$mode://$updatehost/api/dynamicURL/?q=$key&ip=$ipaddr" as-value output=user]
        $logputdebug ("[DynDNS] Result of $updatehost update for $host to $ipaddr: " . ($result->"data"))
    } on-error={
        $logputerror ("[DynDNS] Unable to update $updatehost update for $host to $ipaddr")
    }
}

:local dyndnsUpdate do={
  :global dyndnsUpdateOne
  $dyndnsUpdateOne host=$host key=$key dnstype=ipv4 updatehost="ipv4.cloudns.net" mode=https ipaddr=$ipaddr dns="pns41.cloudns.net"
  if ([:len $key6] > 0) do={
    :local masked6 ([:toip6 $priv6addr] & ::ffff:ffff:ffff:ffff:ffff)
    $dyndnsUpdateOne host=$host key=$key6 dnstype=ipv6 updatehost="ipv6.cloudns.net" mode="https" ipaddr=($ip6addr|$masked6) dns="pns41.cloudns.net"
  }
}

$dyndnsUpdate host=$DynDNSHost key=$DynDNSKey key6=$DynDNSKey6 priv6addr=$DynDNSSuffix6 ip6addr=$ip6addr ipaddr=$ipaddr
$dyndnsUpdate host=$DynDNSHost4 key=$DynDNSKey4 ipaddr=$ipaddr

if ($isprimary) do={
    # BEGIN HOSTS
    $dyndnsUpdate host="auth.foxden.network" priv6addr=fd2c:f4cb:63be:1::e01 key6="NDY2NjQ2Nzo2NTE3NDgxMTI6MjUwZDFlZTk1NGJlYjRhMzcyMWQ0MTM3MjBmNjNjMGI1ZWE5OGNiN2YzMTg4ZDFiODE0OGNlMmVhMzI5NzY0OA" key="NDY2NjQ2Nzo2NTE3NDgwODc6ZmUwYjcyNmI4MjQxY2Q2ZDAyNzRmYTlmNTRiMzhiYmI4NWEzNjBkZjRlNjM4MjU1ZTFkNDA2M2Q2YjY2NjUxNQ" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="darksignsonline.foxden.network" priv6addr=fd2c:f4cb:63be:3::a0f key6="NDY2NjQ2Nzo2NTE3NDgxMjc6YmU0YmI2MWIyMWYzM2RjNjljODI1MTYxMDlhM2Y4NDc1MTFjMjljMmU3ODVmYWM1MjVjM2I2MmYzZTQ2OWFkNQ" key="NDY2NjQ2Nzo2NTE3NDgxNDI6OTRjNzQ1NjlkZGRmMjc1YTE0ZTUzODY4NzAxYTY4NDg1NmE4NGE3Mzg0ZjI1MmY5OTg3MTQwNmEzNWEzMjZiYg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="e621.foxden.network" priv6addr=fd2c:f4cb:63be:3::a0c key6="NDY2NjQ2Nzo2NTE3NDgxNjI6ZmMxZjRiZmY1NjQwN2JiMTkxM2Y1ZmIxZTU1ZDE3MzkxNTlhZTc0YWI4MjE0ZGZmODYzZWE5NTU3NTc2N2YxMA" key="NDY2NjQ2Nzo2NTE3NDgwNjI6MWYzNDRhOTdkNTZkMTIyYzdmNzlkNTljNDczZDI1N2ExYjNhOTUxMDg0NGI2NzVjNWU1NjY0YmJlZjgwNTJiYw" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="foxcaves.foxden.network" priv6addr=fd2c:f4cb:63be:3::a01 key6="NDY2NjQ2Nzo2NTE3NDg0MDc6ZGIyYjE2NGE4MWE4NjY4YWJhNzczMjYwMmJmOGQ2NjhjNzk3ODIxZDBjNDgyOTEwZmI4MGY2ZDc0M2IyZmMxZg" key="NDY2NjQ2Nzo2NTE3NDgwMTI6YzJkMjM5YmEzYmRiNmI3MzI1YTc2ZTAxMmZhMGNhMWFhMmFkNGY2YmU2NmVmYzEyZDFlMGM2MjA4NjAxYmM3OQ" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="furaffinity.foxden.network" priv6addr=fd2c:f4cb:63be:3::a0d key6="NDY2NjQ2Nzo2NTE3NDgyNTc6YTlkYjdhYjRiZjgwNDNlYTcwNzdhMDdjYTVlZjdjMWIyOWNmZWQ2ZGFmNDNmYmJlMTEyNTgxYjk4OWMwNDk1MQ" key="NDY2NjQ2Nzo2NTE3NDgxNzI6NWUyNzcyYjVjZTNiNzA3NTg3NDU1ZGQxMzgxNjc4ZjQxM2M2NzNlMWEzNzEzYTA3ZmFiMDNiMTJhYzUyZmZhYw" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="git.foxden.network" priv6addr=fd2c:f4cb:63be:3::a02 key6="NDY2NjQ2Nzo2NTE3NDgxODI6OWYxMjk0ZDJmN2NkZGRlYjVhZjJmYzcxNjI0NTVlOTYxNzQ0MDA2YTA4YTVhZDQ0YjQ0ZGQyZjgyMzAzY2UyMQ" key="NDY2NjQ2Nzo2NTE3NDgzNjc6YTdmNTA5MWJmNzQ2YzcwODBiNTY2Nzk4NzE3ODM1ZTI2ODlkNjljNDllZDJlMDI5OTUyYTI1ZWZhNDAyZmU2YQ" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="grafana.foxden.network" priv6addr=fd2c:f4cb:63be:2::b05 key6="NDY2NjQ2Nzo2NTE3NDc5OTI6Y2YzOGFiZjU3ZDE4ZDk5ZDQyM2JjNWJjNTQzMTVkNzJjMTExYmFkNWRiN2UxZDc2ZjExNmFmY2E2ZmMzNWE5MQ" key="NDY2NjQ2Nzo2NTE3NDgwMjc6ZDA2OTg5OTVjNzhkZjdkODM3OGUxZGYzZTYzYTc0N2M5OTBhNTk4ZWNkZmY1YjYzZWFmMDUzZWM5MWIyZDMyNg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="homeassistant.foxden.network" priv6addr=fd2c:f4cb:63be:2::c02 key6="NDY2NjQ2Nzo2NTE3NDgyOTc6NmZmMjk3MmZiZWE2NjNhOGU4MTY0MDI5MTg5ZjQwZGIwYzlkYWJlZDZjZmRhYzk4NTc4MzA5ZmRjN2VlODA1MA" key="NDY2NjQ2Nzo2NTE3NDgwOTc6Y2MwNjFhODA3NmM5ZTlkNTMyN2I1YTk4MDkwNDYzZGZjNTdlMzVhYmM5ZWI1ODA3OGRiOWMwOTdmYjFlNThhYg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="jellyfin.foxden.network" priv6addr=fd2c:f4cb:63be:2::b03 key6="NDY2NjQ2Nzo2NTE3NDgwOTI6NDJlNWUzN2NlODIzZDk5MjExZTRmYWNiNGJmNDYxMDIyZDExYzJkZmFlNDkzMGEyZjViNWNlMmY4MmM4NzliOA" key="NDY2NjQ2Nzo2NTE3NDgxMzc6ZWJiZWM4NGNiNzFlOTkzYTE2NmY4NWJhMzRmYzMxMTRiZDdmMTQ4NzljMWNhMjk3N2IxYTQ1ZjVmODQ4NTAyMA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="kiwix.foxden.network" priv6addr=fd2c:f4cb:63be:2::b06 key6="NDY2NjQ2Nzo2NTE3NDc5ODc6NWM4YjFiNWQxMWZkNGVlY2EzYjdkNjAwNDVmMjc3Y2Q3MWFlOWQwMjA5MGNiMTc4YjhhZTFkMjZlOGM0OTJlYQ" key="NDY2NjQ2Nzo2NTE3NDg0Mzc6YTQwMzM0NGU1NTYxZjJkMGE5NTJiYjNlYTlkNDRlOWJkMDJmY2U4ZmYwMGViNzUxOTU3MmUzNzEzNmUyZjgyNg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="minecraft.foxden.network" priv6addr=fd2c:f4cb:63be:3::a08 key6="NDY2NjQ2Nzo2NTE3NDc5NzI6ODY3MmI2OTU5NWIyMjIzZWZjNzFmN2ZjNGYwNzM4ZWQ5ZTczMTlhNGMzYjRlNDA2NzAwMjVjMGNkZDBlMjk4Mg" key="NDY2NjQ2Nzo2NTE3NDgyMTc6Njc0NTYzMTY1YTcxODVhMzVhZDBhNDcxYjQ4NmQzY2JkZTQxZTNhODE5ZjExMDY5MzdlZDE4NjRmODQxNGViOQ" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="mirror.foxden.network" priv6addr=fd2c:f4cb:63be:3::a0b key6="NDY2NjQ2Nzo2NTE3NDg0NTc6ZDNmMDk1NmFlM2U5ZDYzZjY1MzliYmNkNTgyYjZhNGFlNDY1MGM2ZmE5NTY2YWVkM2IwN2QyOTkxMDIzN2QyMA" key="NDY2NjQ2Nzo2NTE3NDg0Nzc6MmI4OTgyMzljMzhjNGJjOTlkZTIzZTc3MGM1MWUwMDAzOWRmYzE4MTliYWZlNjdlYWVmOWExNzE0NmQyNzViMA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="nas.foxden.network" priv6addr=fd2c:f4cb:63be:2::b01 key6="NDY2NjQ2Nzo2NTE3NDgwMzc6MWFhZjE2NjM3MTkyOWM2MjU5MzJkNWRlN2Q5YTQ3OWQ5YjMxZDI0YTgyYTEwNTg5NGQ2OThlZjBjYmZjZTAyMQ" key="NDY2NjQ2Nzo2NTE3NDgxMTc6YjZhZWU3MWRkYzk0MDVkZTQ3OWY0NWJkMWZiNmFjNjhhZjFkMzliNmFjYjNlNjdlMzZkMWI5ODcyNjVhY2RkYg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="nvr.foxden.network" priv6addr=fd2c:f4cb:63be:5::a01 key6="NDY2NjQ2Nzo2NTE3NDgzMzc6YjA0N2IxMjY1NDNiYzZlYWRiMGJmNjcwMjRlNDAyMjVhNzhmMTg1NzFjYWYzMWJiMDNlNjRlOGVlYjM5NmEzNg" key="NDY2NjQ2Nzo2NTE3NDgwODI6ZDFlMDlhOGY1YTMzYWZjNDE4MzZjMDNjOWFkMzU3MWMyZDNlM2NjZGM0YTQ4MjgyNjQzODZkZjAzMDY4MTYwYg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="radius.auth.foxden.network" priv6addr=fd2c:f4cb:63be:1::e02 key6="NDY2NjQ2Nzo2NTE3NDgxNTI6OTgwOWUzMjVjMGMwNDBmMTE3YjU0NTc2NTJjOTViZTZmMjI0YmM2MDExNTFhZDU4MzNkNjg2MjM1NzVjOWFmZg" key="NDY2NjQ2Nzo2NTE3NDgxNTc6ZDRmOTk4ODQwYzA3NjQ5OTEyZWY5NDA0ODlkNmQ0MDM2Y2QxZTVjNjZmZGYyYTBkNDM1NGE3YmFmOThlZDZhZA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="restic.foxden.network" priv6addr=fd2c:f4cb:63be:2::b0c key6="NDY2NjQ2Nzo2NTE3NDgzNDI6MGEzMjBkMTNjODllMTllZjk3YmFiNGYwNDE5OWJmMGExMTZlNjZjODRkYTY2NDkyZWJkYWMyMTU2MzE2MDljZQ" key="NDY2NjQ2Nzo2NTE3NDgxMDI6ZTM3ODczMjIzNGQ1ZmMxYzIxOTlkM2FiYTA4NjFmMzYzZGZiNmU5OTMyZTJiOGRlNDAyYTE2MmNhMGJjMjBmMw" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="spaceage-api.foxden.network" priv6addr=fd2c:f4cb:63be:3::a05 key6="NDY2NjQ2Nzo2NTE3NDgxMzI6ZmZmMDgwM2U2Mjg4YzMyOWYyZWYyMjJlMzQzMjFkZTNiNjRjNDc2YzdjY2RhOTUwNmY0MmE0YTYwMzk2MDQ1Yw" key="NDY2NjQ2Nzo2NTE3NDgzODc6NmE1M2IwOTlhYjFiNTJiYzdhYzU1NWU1MTE0MjQ3NGMyZGU4YzhjNTQzZDFmZDNkNjI5OTFmOTQyNTBjY2VhZQ" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="spaceage-gmod.foxden.network" priv6addr=fd2c:f4cb:63be:3::a04 key6="NDY2NjQ2Nzo2NTE3NDgwMDI6YjRiOGQ1NGQyMGQ1MzljMjhjYzcyYTdiOWU2YWI4MmQ4NzAxNDZiYmM2NjY5Y2RmOTU5OWI3OTgzM2I0ZDJhYg" key="NDY2NjQ2Nzo2NTE3NDg0Mjc6NzQ4NjRmMjNlYjU5Y2E0YTUyOTg5ZTIwMDQwMDU3Y2JjMmE5MDU5YTc3YTZhYmIwYzg2YjJlMTk4MWRjMzA0ZA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="spaceage-tts.foxden.network" priv6addr=fd2c:f4cb:63be:3::a06 key6="NDY2NjQ2Nzo2NTE3NDg0NzI6YmFjN2QyYmY4MDU2ZWI2NzVjZmQxMzIyNTg1YzdjMmQ5NGJhOGU4NGI1M2QwZjkxZjVlYmJlNWRiZjNiMDZmMA" key="NDY2NjQ2Nzo2NTE3NDgyNjI6ZjllYjU2ZDc4MGYxYjlmY2I3N2IwYTA0NzBhMjhkYTVmMGE4Y2E2ZTY1Mjc3NjdmYWU1MmI0ODMyODNkYjU3Yw" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="spaceage-website.foxden.network" priv6addr=fd2c:f4cb:63be:3::a09 key6="NDY2NjQ2Nzo2NTE3NDgwNzI6ZTM4YjUxZTVlYmJmNTBjMTA4NDk1OGNlZDlhZmM5MmIxNmRlYjc0ODgzZTMwNTNmMTJiMmY5ZGU4YzVkODE0YQ" key="NDY2NjQ2Nzo2NTE3NDgzMTc6MzdlMDE0ZDhhMDFkNjg2ZmFlY2E1ZDlhZmNhMWI5NjkxNGQ3ZTY4MjNhNTQzYTdlYTE4ZmQ3ODk5ZjM2ZDU4OA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="syncthing.foxden.network" priv6addr=fd2c:f4cb:63be:2::b02 key6="NDY2NjQ2Nzo2NTE3NDg0NDc6ZTQ3OTA2ZmNiZmViZmNlNTM5OTZkYjc4YWFkN2RjNDE3MmZiOWMyMmI4N2JiZWFmNmY4OWMzNDAxOGFlZTQ4Ng" key="NDY2NjQ2Nzo2NTE3NDgwNjc6YmJiYTVhZTc3MDQwMjYxMTgzNjIzNmMwOTkwNTVkYjY3NmY1NGVjYTY5YzZhOWJmN2M0ZWQ2YzZhYzRkMGFjNA" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="unifi.foxden.network" priv6addr=fd2c:f4cb:63be:1::a01 key6="NDY2NjQ2Nzo2NTE3NDgxNDc6ZmI1OGZjMTFkODBmYjhlMjAwMzBhMjNhZWY1Y2I3MmNkOWM3MzBjNzYyZjk0Mjk0ZWVlOGY0YTZkMzNjYWJiMQ" key="NDY2NjQ2Nzo2NTE3NDgzODI6NWYwNTQ5MTg0MDM4OWQ4YjQ2YzZlMTM1NGQ0MjRhZDQzOGNkZTJjM2FhZWE5N2E5OTUxMzA3MjU5YTRjODkwZg" ip6addr=$ip6addr ipaddr=$ipaddr
    $dyndnsUpdate host="website.foxden.network" priv6addr=fd2c:f4cb:63be:3::a0a key6="NDY2NjQ2Nzo2NTE3NDgwNDI6MjVkNDkwMWQ3MjlhZjU0YzM1MjQ5MmIxYmUzOWJkOWEzZDdiYmRkOTdmM2JmZjU2YTk2ZTQyNTU3ZTQ1ZDE1YQ" key="NDY2NjQ2Nzo2NTE3NDgyNzc6ZGRhN2RjZmE3NDg5ZTVlNTAyYjFmOTBhOGUwNmM5NzRjZjg0YTk5YWU2NGYyODZiOGZiMDY4OWNiN2E4N2JjMw" ip6addr=$ip6addr ipaddr=$ipaddr
    # END HOSTS
}
