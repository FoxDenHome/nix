/system/script/run gen-dhcp
/system/script/run gen-firewall
:put Done

:do {
    /file/add name=container-restart-all
} on-error={}
