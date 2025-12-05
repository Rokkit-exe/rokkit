#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"

set -e

if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "../../config/settings.conf not found."
    exit 1
fi
source "$ROOT_DIR/config/settings.conf"

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo "GIT_NAME and GIT_EMAIL environment variables must be set."
    exit 1
fi

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
