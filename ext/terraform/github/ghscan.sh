#!/bin/bash

set -euo pipefail

TFSTATE="tfstate+s3://foxden-tfstate/$(cat providers.tf | grep -oP '"[^"]+\.tfstate"' | tr -d '"')"

export GITHUB_OWNER=
export GITHUB_ORGANIZATION="$(cat providers.tf | grep -oP 'owner\s+=\s+"[^"]+"' | cut -d= -f2 | tr -d ' \t"')"

case $GITHUB_ORGANIZATION in
  Doridian)
    export GITHUB_OWNER="${GITHUB_ORGANIZATION}"
    ;;
esac

verify_env() {
    varname="$1"
    varval="${!varname}"
    if [ -z "${varval}" ]; then
        echo "Missing required environment variable: $1"
        exit 1
    fi

    echo "$varname=${varval}"
}

GITHUB_VERSION="$(cat .terraform.lock.hcl | grep -P 'provider "registry.opentofu.org/integrations/github"' -A1 | tail -1 | grep -oP 'version\s+=\s+"[^"]+"' | cut -d= -f2 | tr -d ' \t"')"

verify_env GITHUB_VERSION
if [ -z "${GITHUB_OWNER-}" ]; then
    verify_env GITHUB_ORGANIZATION
else
    export GITHUB_ORGANIZATION=
    verify_env GITHUB_OWNER
fi
verify_env TFSTATE

driftctl scan -f "${TFSTATE}" -t 'github+tf'  --tf-provider-version "${GITHUB_VERSION}"
