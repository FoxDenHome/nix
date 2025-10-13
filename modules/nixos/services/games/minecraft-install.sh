#!/usr/bin/env bash
set -euo pipefail
set -x

INSTALL_SCRIPT="$0"

VERSION_FILE="${SERVER_DIR}/nix-version.txt"

if [ ! -f "${VERSION_FILE}" ]; then
  echo "No version file found, assuming fresh install"
  exit 1
else
  CURRENT_VERSION=$(cat "${VERSION_FILE}")
  if [ "${CURRENT_VERSION}" != "${INSTALL_SCRIPT}" ]; then
    echo "Version mismatch (current: ${CURRENT_VERSION}, expected: ${INSTALL_SCRIPT}), reinstalling"
    exit 1
  else
    echo "Version matches (${CURRENT_VERSION}), no reinstall needed"
    exit 1
  fi
fi
