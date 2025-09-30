#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

export MIRROR_TARGET="/data"
export LOCAL_DIR="${MIRROR_TARGET}/.dori-local"
export LASTPULL_BASE="${LOCAL_DIR}/lastpull"

mkdir -p "${LOCAL_DIR}"

if [ -z "${MIRROR_SOURCE_HTTPS-}" ]; then
	export LASTUPDATE_URL=''
else
	export LASTUPDATE_URL="${MIRROR_SOURCE_HTTPS}/lastupdate"
fi

echo "[LOOP] Upstream mirror: ${MIRROR_SOURCE_RSYNC} / ${MIRROR_SOURCE_HTTPS-}"

while :; do
    if [ -z "${MIRROR_FORCE_SYNC-}" ]; then
        # Sleep between 0 minutes and 60 minutes before starting the sync
        nextsleep="$[RANDOM%60]"
        echo "[LOOP] Pre-Sleeping for ${nextsleep} minutes"
        sleep "${nextsleep}m" || true
    fi

    echo '[LOOP] Running ./sync.sh'
    ecode=0
    bash ./sync.sh || ecode=$?
    echo "[LOOP] Sync completed with code: ${ecode}"

    date '+%s' > "${LASTPULL_BASE}"
    if [ "${ecode}" -eq 0 ]; then
        cp -f "${LASTPULL_BASE}" "${LASTPULL_BASE}-success"
    else
        cp -f "${LASTPULL_BASE}" "${LASTPULL_BASE}-error"
    fi

    # Slep at least until the next full hour (1 minute to make sure)
    nextsleep="$((61 - $(date +%M)))"
    echo "[LOOP] Post-Sleeping for ${nextsleep} minutes until the next full hour"
    sleep "${nextsleep}m" || true
done
