#!/bin/sh
set -e

transfer_section() {
    SECTION="$1"
    WHERE="$2"
    WHERER="$3"
    if [ -z "$WHERER" ]
    then
        WHERER="$WHERE"
    fi

    echo "$SECTION" >> "$F"
    echo "remove [ find $WHERER ]" >> "$F"

    if [ ! -z "$WHERE" ]
    then
        ssh router.foxden.network "$SECTION/export show-sensitive terse verbose where $WHERE" | dos2unix  >> "$F"
    else
        ssh router.foxden.network "$SECTION/export show-sensitive terse verbose" | dos2unix >> "$F"
    fi
}

transfer_section_localclause() {
    transfer_section "$1" '(!(name~"^local-"))'
}

transfer_section_notdynamic() {
    transfer_section "$1" 'dynamic=no'
}

transfer_section_notdynamic_rmall() {
    transfer_section "$1" 'dynamic=no' ' '
}

transfer_section_notdynamic_expall() {
    transfer_section "$1" ' ' 'dynamic=no'
}

F="$(mktemp)"
chmod 600 "$F"
echo > "$F"

transfer_section '/ip/dns/static'
transfer_section_notdynamic_rmall '/ip/dhcp-server/lease'
transfer_section_notdynamic_rmall '/ipv6/dhcp-server/binding'
transfer_section_notdynamic_expall '/ip/firewall/filter'
transfer_section_notdynamic_expall '/ip/firewall/mangle'
transfer_section_notdynamic_expall '/ip/firewall/nat'
transfer_section_notdynamic_expall '/ipv6/firewall/filter'
transfer_section_notdynamic_expall '/ipv6/firewall/mangle'
transfer_section_notdynamic_expall '/ipv6/firewall/nat'
transfer_section_localclause '/system/scheduler'

scp "$F" router-backup.foxden.network:/tmpfs-scratch/transfer.rsc
ssh router-backup.foxden.network '/import file-name=tmpfs-scratch/transfer.rsc'
sleep 1
ssh router-backup.foxden.network '/file/remove tmpfs-scratch/transfer.rsc'

rm -f "$F"

ssh router.foxden.network '/system/script/run firewall-update'
ssh router-backup.foxden.network '/system/script/run firewall-update'

transfer_files() {
    cd files
    scp -r . "$1:/"
    ssh "$1" '/file/add name=container-restart-all' || true
    cd ..
}

transfer_files router.foxden.network
ssh router.foxden.network '/system/script/run reconfigure'

transfer_files router-backup.foxden.network
ssh router-backup.foxden.network '/system/script/run reconfigure'
