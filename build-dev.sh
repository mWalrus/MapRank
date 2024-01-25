DEV_DIR="$PWD/dev-builds"
ARCHIVE_PATH="$DEV_DIR/MapRank-Dev.op"

if [ ! -d "$DEV_DIR" ]; then
  mkdir "$DEV_DIR"
fi

cp ./info.toml ./info.toml.old
sed -E -i "3s/Map Rank/Map Rank Dev/I" ./info.toml

if [ -f "$ARCHIVE_PATH" ]; then
  rm -rf "$ARCHIVE_PATH"
fi

command -v zip > /dev/null && zip "$ARCHIVE_PATH" ./src/*.as ./info.toml || printf "Failed to build release archive"
cp -f "$ARCHIVE_PATH" "$HOME/.steam/steam/steamapps/compatdata/2225070/pfx/drive_c/users/steamuser/OpenplanetNext/Plugins"

mv ./info.toml.old ./info.toml

