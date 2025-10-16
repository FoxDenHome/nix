#!/bin/sh
set -ex

scp "$1" router-backup.foxden.network:/tmpfs-scratch/scripts.rsc
ssh router-backup.foxden.network "/import file-name=tmpfs-scratch/scripts.rsc"
ssh router-backup.foxden.network "/file/remove tmpfs-scratch/scripts.rsc"
