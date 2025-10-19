#!/bin/sh
set -e

transfer_files() {
    cd files
    scp -r . "$1:/"
    cd ..
}

uv run refresh.py
./scripts.sh

transfer_files router.foxden.network
ssh router.foxden.network '/system/script/run reconfigure'

transfer_files router-backup.foxden.network
ssh router-backup.foxden.network '/system/script/run reconfigure'
