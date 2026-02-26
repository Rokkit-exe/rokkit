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

if [ ! -f /etc/locale.gen ]; then
    echo "Error: /etc/locale.gen not found."
    exit 1
fi

# uncomment the desired locale in /etc/locale.gen and generate it
sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen

# comment en_US.UTF-8 if LOCALE is different
if [ "$LOCALE" != "en_US.UTF-8" ]; then
    sed -i "s/^${LOCALE} UTF-8/#${LOCALE} UTF-8/" /etc/locale.gen
fi

locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
