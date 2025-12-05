#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"
set -e

if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "$ROOT_DIR/config/settings.conf not found."
    exit 1
fi
source "$ROOT_DIR/config/settings.conf"


if [ -z "$LOCALE" ]; then
    echo "Error: LOCALE is not set in $ROOT_DIR/config/settings.conf."
    exit 1
fi

echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
