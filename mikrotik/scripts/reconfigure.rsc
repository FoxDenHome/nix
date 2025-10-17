/system/script/run dhcp-leases-reload
:put Done

:do {
    /file/add name=container-restart-all
} on-error={}
