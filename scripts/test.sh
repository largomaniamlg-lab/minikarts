#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine="${GODOT_BIN:-}"
if [[ -z "$engine" ]]; then
  if [[ -x /workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64 ]]; then
    engine=/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64
  else
    engine=godot
  fi
fi
runtime_dir="$(mktemp -d "${TMPDIR:-/tmp}/minikarts-tests.XXXXXX")"
trap 'rm -rf -- "$runtime_dir"' EXIT
export XDG_CACHE_HOME="$runtime_dir/cache"
export XDG_DATA_HOME="$runtime_dir/data"
export XDG_CONFIG_HOME="$runtime_dir/config"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
version="$("$engine" --version)"
if [[ "$version" != 4.5.1.stable* ]]; then
  printf 'Se requiere Godot 4.5.1 estable; encontrado: %s. Configura GODOT_BIN.\n' "$version" >&2
  exit 1
fi
"$engine" --headless --path "$repo_dir/godot" --editor --import --quit
"$engine" --headless --path "$repo_dir/godot" --script tests/v02_test.gd -- --force-touch
"$engine" --headless --path "$repo_dir/godot" --script tests/desktop_test.gd
PORT=0 "$engine" --headless --path "$repo_dir/godot" --script tests/multiplayer_rules.gd -- --server
PORT=0 "$engine" --headless --path "$repo_dir/godot" --script tests/network_motion_test.gd -- --server
"$engine" --headless --path "$repo_dir/godot" --fixed-fps 60 --script tests/offline_race_test.gd

"$engine" --headless --path "$repo_dir/godot" --script tests/handling_test.gd

PORT=0 "$engine" --headless --path "$repo_dir/godot" --script tests/tournament_test.gd -- --server
"$engine" --headless --fixed-fps 60 --path "$repo_dir/godot" --script tests/circuits_test.gd

"$engine" --headless --path "$repo_dir/godot" --script tests/offline_tournament_test.gd

"$engine" --headless --path "$repo_dir/godot" --script tests/menu_test.gd

"$engine" --headless --path "$repo_dir/godot" --script tests/boost_theme_test.gd

PORT=0 "$engine" --headless --path "$repo_dir/godot" --script tests/server_boost_test.gd -- --server
