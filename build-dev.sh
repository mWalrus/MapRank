mkdir "$PWD/dev-builds"

cp ./info.toml ./info.toml.old
sed -E -i "3s/Map Rank/Map Rank Dev/I" ./info.toml

command -v zip > /dev/null && zip "$PWD/dev-builds/MapRank-Dev.op" ./*.as ./info.toml || printf "Failed to build release archive"
cp -f "$PWD/dev-builds/MapRank-Dev.op" "$HOME/.steam/steam/steamapps/common/Trackmania/Openplanet/Plugins/"

mv ./info.toml.old ./info.toml

