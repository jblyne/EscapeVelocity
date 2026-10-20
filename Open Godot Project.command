#!/bin/zsh
set -e
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
open -n "$project_dir/.tools/Godot.app" --args --editor --path "$project_dir/godot"
