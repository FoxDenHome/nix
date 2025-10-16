:foreach bid in=[/ipv6/dhcp-server/binding/find dynamic] do={
    :local binding [/ipv6/dhcp-server/binding/get $bid]
    :local macfind [/ipv6/neighbor/find address=$binding->"client-address"]
    :if ([:len $macfind] > 0) do={
        :local macaddr [/ipv6/neighbor/get ($macfind->0)  mac-address]
        :local dhcpfind [/ip/dhcp-server/lease/find mac-address=$macaddr dynamic=no]
        :if ([:len $dhcpfind] > 0) do={
            :local dhcp [/ip/dhcp-server/lease/get ($dhcpfind->0) ]

            :local pool ($binding->"prefix-pool")
            :if (!($pool ~ "-full\$")) do={
                :set pool ($pool."-full")
            }

           :local ipv4vlan [:tonum ($dhcp->"address" & 0.255.0.0 >> 16)]
           :local ipv4suffix ($dhcp->"address"  & 0.0.255.255)

           :local ipv6vlan [:convert $ipv4vlan from=num to=hex]
           :local ipv6suffix [:convert $ipv4suffix from=num to=hex]
           :local ipv6 [:toip6 "fd2c:f4cb:63be:$ipv6vlan::$ipv6suffix"]

            :put ("Binding ".$dhcp->"comment"." ipv6-tmp=".$binding->"client-address"." mac=".$macaddr." ipv4=".$dhcp->"address"." suffix=".$ipv4suffix." vlan=".$ipv4vlan." ipv6=".$ipv6)

            :if ($binding->"dynamic") do={
                /ipv6/dhcp-server/binding/make-static $bid
            }
            /ipv6/dhcp-server/binding/set $bid address=$ipv6 life-time=1d prefix-pool=$pool comment=($dhcp->"comment")
        }
    }
}
