#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine="${GODOT_BIN:-/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.minikarts-cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.minikarts-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.minikarts-config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
[[ "$("$engine" --version)" == 4.5.1.stable* ]] || { echo 'Se requiere Godot 4.5.1 estable.' >&2; exit 1; }
output_dir="$(mktemp -d "${TMPDIR:-/tmp}/minikarts-web.XXXXXX")"
"$engine" --headless --path "$repo_dir/godot" --editor --import --quit
"$engine" --headless --path "$repo_dir/godot" --export-release Web "$output_dir/game.html"
cp "$repo_dir/index.html" "$output_dir/index.html"
python3 "$repo_dir/scripts/prepare-web.py" "$output_dir/game.html"
printf 'Exportación local lista en: %s\n' "$output_dir"
