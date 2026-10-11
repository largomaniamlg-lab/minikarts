#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine="${GODOT_BIN:-/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/minikarts-server/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/minikarts-server/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/minikarts-server/config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
[[ "$("$engine" --version)" == 4.5.1.stable* ]] || { echo 'Se requiere Godot 4.5.1.' >&2; exit 1; }
case "${1:-}" in
  --preimported)
    [[ -f "$repo_dir/godot/.godot/uid_cache.bin" && -d "$repo_dir/godot/.godot/imported" ]] || {
      echo 'Faltan recursos importados en la imagen; reconstruye el contenedor.' >&2
      exit 1
    }
    ;;
  ""|--import-only)
    "$engine" --headless --path "$repo_dir/godot" --editor --import --quit
    [[ "${1:-}" != --import-only ]] || exit 0
    ;;
  *) echo 'Uso: server.sh [--import-only|--preimported]' >&2; exit 1 ;;
esac
exec "$engine" --headless --path "$repo_dir/godot" -- --server
