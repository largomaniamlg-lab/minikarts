#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine="${GODOT_BIN:-/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/minikarts-server/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/minikarts-server/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/minikarts-server/config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
[[ "$("$engine" --version)" == 4.5.1.stable* ]] || { echo 'Se requiere Godot 4.5.1.' >&2; exit 1; }
"$engine" --headless --path "$repo_dir/godot" --editor --import --quit
exec "$engine" --headless --path "$repo_dir/godot" -- --server
