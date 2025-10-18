/system/script/run gen-dhcp
:put Done

:do {
    /file/add name=container-restart-all
} on-error={}
