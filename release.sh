#!/bin/sh
VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+(rc-[0-9]+)?"

printf "Version (ex. 1.10.2): " >&2
read -r VERSION

sed -E -i "2s/$VERSION_REGEX/$VERSION/I" ./info.toml

command -v zip > /dev/null && zip "MapRank-v$VERSION.op" ./*.as ./info.toml || printf "Failed to build release archive"
