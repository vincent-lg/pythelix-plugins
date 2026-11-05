#!/bin/sh
# Publish every plugin version that isn't in the index yet, and update the index.
#
# Usage: ci/publish.sh <registry directory> <engine directory>
#
# Needs GITHUB_REPOSITORY, and a `gh` allowed to create releases. Every plugin is
# validated first: nothing is published unless all of them pass.
set -eu

registry=$(cd "$1" && pwd)
engine=$(cd "$2" && pwd)
dist=$(mktemp -d)
trap 'rm -rf "$dist"' EXIT

cd "$engine"

for directory in "$registry"/plugins/*/; do
    key=$(basename "$directory")
    PLUGINS_PATH="$registry/plugins" mix pythelix.plugin package "$key" \
        --index "$registry/index.json" --output "$dist"
done

for archive in "$dist"/*.tar.gz; do
    [ -e "$archive" ] || continue

    name=$(basename "$archive" .tar.gz)
    # The version is what follows the last hyphen before a number: a key can hold
    # hyphens, and so can a pre-release.
    version=$(echo "$name" | sed -E 's/^.*-([0-9]+\.[0-9]+.*)$/\1/')
    key=${name%-"$version"}
    tag="$key-v$version"
    url="https://github.com/$GITHUB_REPOSITORY/releases/download/$tag/$name.tar.gz"

    # A run stopped halfway may have left the release without updating the index.
    if gh release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
        gh release upload "$tag" "$archive" --clobber --repo "$GITHUB_REPOSITORY"
    else
        gh release create "$tag" "$archive" --repo "$GITHUB_REPOSITORY" \
            --title "$key $version" --notes "$key $version"
    fi

    mix pythelix.plugin index "$registry/index.json" "$archive" "$url"
done
