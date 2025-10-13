#!/usr/bin/env bash
set -euo pipefail
set -x

INSTALL_SCRIPT="$0"

VERSION_FILE="${SERVER_DIR}/nix-version.txt"

run_update() {
    echo "${INSTALL_SCRIPT}" > "${VERSION_FILE}"
}

if [ ! -f "${VERSION_FILE}" ]; then
  echo "No version file found, assuming fresh install"
  run_update
else
  CURRENT_VERSION=$(cat "${VERSION_FILE}")
  if [ "${CURRENT_VERSION}" != "${INSTALL_SCRIPT}" ]; then
    echo "Version mismatch (current: ${CURRENT_VERSION}, expected: ${INSTALL_SCRIPT}), reinstalling"
    run_update
  else
    echo "Version matches (${CURRENT_VERSION}), no reinstall needed"
    exit 0
  fi
fi
