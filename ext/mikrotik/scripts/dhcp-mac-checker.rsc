:local dhcpent
:local arpmac
:local arpfind

:foreach i in=[/ip/dhcp-server/lease/find status!=bound dynamic=no] do={
    :set dhcpent [/ip/dhcp-server/lease/get $i]

    {
        :local jobID [:execute {:ping count=5 address=($dhcpent->"address")}]
        :while ([:len [/system/script/job/find .id=$jobID]] > 0) do={
            :set arpfind [/ip/arp/find address=($dhcpent->"address") mac-address!=""]
            if ([:len $arpfind] > 0) do={
                :do { /system/script/job/remove $jobID } on-error={}
            } else={
                :delay 1s
            }
        }

        if ([:len $arpfind] = 0) do={
            :set arpfind [/ip/arp/find address=($dhcpent->"address") mac-address!=""]
        }
    }

    :set arpmac "N/A"
    :if ([:len $arpfind] > 0) do={
        :set arpmac [/ip/arp/get ($arpfind->0) mac-address]
    }

    :if ([:typeof $arpmac] = "nil" || $arpmac = "") do={
        :set arpmac "N/A"
    }

    :if ($arpmac != ($dhcpent->"mac-address")) do={
        :put ("# IP: " . ($dhcpent->"address") . " | DHCP MAC: " . ($dhcpent->"mac-address") . " | ARP MAC: " . $arpmac . " | Comment: " . ($dhcpent->"comment"))
        :if ($arpmac != "N/A") do={
            :put ("/ip/dhcp-server/lease set [/ip/dhcp-server/lease find address=" . ($dhcpent->"address") . "] mac-address=" . $arpmac)
        }
    }
}

