/system/script/run gen-dhcp
/system/script/run firewall-update
:put Done

:do {
    /file/add name=container-restart-all
} on-error={}
