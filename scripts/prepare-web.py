"""Enable mobile controls in the freshly generated, unthreaded Web export."""
import json
import gzip
import re
import sys
from pathlib import Path

page = Path(sys.argv[1])
text = page.read_text()
pattern = r'const GODOT_CONFIG = (\{[^\n]*\});'
match = re.search(pattern, text)
if match is None:
    raise RuntimeError('No se encontró la configuración del loader Godot')
config = json.loads(match.group(1))
config['args'] = ['--', '--force-touch']
text = text[:match.start(1)] + json.dumps(config, separators=(',', ':')) + text[match.end(1):]
# Reuse the existing browser decompression loader, preserving its supported route.
existing = (Path(__file__).resolve().parents[1] / 'game.html').read_text()
shim = re.search(r'<script>\s*const originalFetch.*?</script>', existing, re.S)
if shim is None:
    raise RuntimeError('No se encontró el cargador gzip existente')
text = text.replace('<script src="game.js"></script>', shim.group(0) + '\n<script src="game.js"></script>')
if 'const originalFetch' not in text:
    raise RuntimeError('No se pudo insertar el cargador gzip')
wasm = page.parent / 'game.wasm'
binary = wasm.read_bytes()
(page.parent / 'game.wasm.gz').write_bytes(gzip.compress(binary, mtime=0))
wasm.unlink()
page.write_text(text)
