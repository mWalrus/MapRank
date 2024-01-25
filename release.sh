#!/bin/sh
VERSION_REGEX="[0-9]+\.[0-9]+(\.[0-9]+)?(rc-[0-9]+)?"
INFO_FILE="./info.toml"

CURRENT_VERSION=$(grep -E -o "$VERSION_REGEX" $INFO_FILE)
printf "Version (currently %s): " "$CURRENT_VERSION" >&2
read -r VERSION

sed -E -i "2s/$VERSION_REGEX/$VERSION/I" $INFO_FILE

ARCHIVE_PATH="$PWD/releases/MapRank-v$VERSION.op"

if [ -f "$ARCHIVE_PATH" ]; then
  rm -rf "$ARCHIVE_PATH"
fi

command -v zip > /dev/null && zip "$ARCHIVE_PATH" ./src/*.as ./info.toml || printf "Failed to build release archive"
