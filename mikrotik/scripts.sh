#!/bin/sh
set -e

DEFAULT_DONTREQUIREPERMS=no
DEFAULT_POLICY='ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon'

F="$(mktemp)"

echo '/system/script/remove [ find where (!(name~"^local-"))]' >> "$F"
echo '/system/scheduler/remove [ find where (!(name~"^local-"))]' >> "$F"

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

    echo "/system/script/add name=\"$script_name\" dont-require-permissions=$script_dontrequireperms policy=$script_policy source=$(echo '0' | jq --rawfile src "$script_file" '$src' | sed 's/\$/\\$/g')" >> "$F"

    if grep -q '^# schedule=' "$script_file"; then
        script_schedule=$(grep '^# schedule=' "$script_file" | cut -d'=' -f2)
        if [ "$script_schedule" = "startup" ]; then
            schedule_param="start-time=startup interval=00:00:00"
        else
            schedule_param="interval=$script_schedule"
        fi
        echo "/system/scheduler/add name=\"$script_name\" $schedule_param on-event=\"/system/script/run $script_name\"" >> "$F"
    fi
done

cat "$F"

runscripts() {
    remote="$1"
    scp "$F" "$remote:/tmpfs-scratch/scripts.rsc"
    ssh "$remote" "/import file-name=tmpfs-scratch/scripts.rsc"
    ssh "$remote" "/file/remove tmpfs-scratch/scripts.rsc"
}

runscripts router.foxden.network
runscripts router-backup.foxden.network

rm -f "$F"
