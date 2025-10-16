#!/bin/sh
set -e

DEFAULT_DONTREQUIREPERMS=no
DEFAULT_POLICY='ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon'

F="$(mktemp)"

for script_file in $(ls -1 scripts/*.rsc); do
    script_name="$(basename "$script_file" .rsc)"
    script_policy="${DEFAULT_POLICY}"
    script_dontrequireperms="${DEFAULT_DONTREQUIREPERMS}"

    if grep -q '^# policy=' "$script_file"; then
        script_policy=$(grep '^# policy=' "$script_file" | cut -d'=' -f2)
    fi

    if grep -q '^# dontrequireperms=' "$script_file"; then
        script_dontrequireperms=$(grep '^# dontrequireperms=' "$script_file" | cut -d'=' -f2)
    fi

    echo ":do { /system/script/add name=\"$script_name\" source=\"# dummy script will be replaced\" } on-error={}" >> "$F"
    echo "/system/script/set [ /system/script/find name=\"$script_name\" ] dont-require-permissions=$script_dontrequireperms  policy=$script_policy source=$(echo '0' | jq --rawfile src "$script_file" '$src' | sed 's/\$/\\$/g')" >> "$F"
done

runscripts() {
    remote="$1"
    scp "$F" "$remote:/tmpfs-scratch/scripts.rsc"
    ssh "$remote" "/import file-name=tmpfs-scratch/scripts.rsc"
    ssh "$remote" "/file/remove tmpfs-scratch/scripts.rsc"
}

runscripts router.foxden.network
runscripts router-backup.foxden.network

rm -f "$F"
