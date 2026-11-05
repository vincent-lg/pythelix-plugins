#!/bin/sh
# Validate every plugin the way publishing will, building nothing that stays.
#
# Usage: ci/validate.sh <registry directory> <engine directory>
set -eu

registry=$(cd "$1" && pwd)
engine=$(cd "$2" && pwd)
dist=$(mktemp -d)
trap 'rm -rf "$dist"' EXIT

cd "$engine"

status=0

for directory in "$registry"/plugins/*/; do
    key=$(basename "$directory")
    echo "::group::$key"

    if ! PLUGINS_PATH="$registry/plugins" mix pythelix.plugin package "$key" \
        --index "$registry/index.json" --output "$dist"; then
        echo "::error::$key did not pass validation"
        status=1
    fi

    echo "::endgroup::"
done

exit $status
