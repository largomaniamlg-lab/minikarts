#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine="${GODOT_BIN:-/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64}"
if [[ ! -x "$engine" ]]; then engine=godot; fi
exec "$engine" --path "$repo_dir/godot" --rendering-method mobile res://scenes/toon_demo.tscn "$@"
