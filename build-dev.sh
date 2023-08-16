mkdir "$PWD/dev-builds"
command -v zip > /dev/null && zip "$PWD/dev-builds/MapRank-Dev.op" ./*.as ./info.toml || printf "Failed to build release archive"
cp -f "$PWD/dev-builds/MapRank-Dev.op" "$HOME/.steam/steam/steamapps/common/Trackmania/Openplanet/Plugins/"

