:put "Adjusting lease times"
/ip/dhcp-server/lease set [/ip/dhcp-server/lease find dynamic=no] lease-time=1d
:put Done

:do {
    /file/add name=container-restart-all
} on-error={}
