#!/usr/bin/env bash
set -euo pipefail
tools=/workspace/.minikarts-tools
mkdir -p "$tools"
archive="$tools/templates.tpz"
if [[ ! -f "$archive" ]]; then
  curl -fL --retry 3 https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz -o "$archive.download"
  mv "$archive.download" "$archive"
fi
printf '%s  %s\n' '8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5' "$archive" | sha512sum -c -
python3 - "$archive" "${XDG_DATA_HOME:-/workspace/.minikarts-data}" <<'PY'
import sys
import zipfile
from pathlib import Path
target = Path(sys.argv[2]) / 'godot/export_templates/4.5.1.stable'
target.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in ['version.txt', 'web_nothreads_debug.zip', 'web_nothreads_release.zip']:
        (target / name).write_bytes(archive.read('templates/' + name))
PY
