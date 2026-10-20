#!/bin/zsh
set -e
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -d "$project_dir/builds/Escape Velocity HD.app" ]]; then
  open "$project_dir/builds/Escape Velocity HD.app"
else
  exec "$project_dir/.tools/Godot.app/Contents/MacOS/Godot" --path "$project_dir/godot"
fi
