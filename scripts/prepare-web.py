"""Enable mobile controls in the freshly generated, unthreaded Web export."""
import json
import gzip
import hashlib
import shutil
import os
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
config['virtualKeyboard'] = True
pack = page.parent / 'game.pck'
pack_name = 'game-' + hashlib.sha256(pack.read_bytes()).hexdigest()[:16] + '.pck'
shutil.copyfile(pack, page.parent / pack_name)
config['mainPack'] = pack_name
config['fileSizes'][pack_name] = pack.stat().st_size
text = text[:match.start(1)] + json.dumps(config, separators=(',', ':')) + text[match.end(1):]
# Reuse the existing browser decompression loader, preserving its supported route.
existing = (Path(__file__).resolve().parents[1] / 'game.html').read_text()
shim = re.search(r'<script>\s*const originalFetch.*?</script>', existing, re.S)
if shim is None:
    raise RuntimeError('No se encontró el cargador gzip existente')
token = hashlib.sha256((page.parent / 'game.pck').read_bytes()).hexdigest()[:16]
shim_text = re.sub(r"v=[0-9a-f]{16}", 'v=' + token, shim.group(0))
text = text.replace('<script src="game.js"></script>', shim_text + '\n<script src="game.js"></script>')
if 'const originalFetch' not in text:
    raise RuntimeError('No se pudo insertar el cargador gzip')
wasm = page.parent / 'game.wasm'
binary = wasm.read_bytes()
(page.parent / 'game.wasm.gz').write_bytes(gzip.compress(binary, mtime=0))
wasm.unlink()
server_url = os.environ.get('MULTIPLAYER_SERVER_URL', '')
if server_url and not server_url.startswith(('wss://', 'ws://127.0.0.1', 'ws://localhost')):
    raise RuntimeError('MULTIPLAYER_SERVER_URL debe usar wss:// en Internet')
settings = '<script>window.MINIKARTS_SERVER_URL = ' + json.dumps(server_url) + ';</script>'
text = text.replace('<script src="game.js"></script>', settings + '\n<script src="game.js"></script>')
page.write_text(text)

# The published landing page may refer to an older versioned HTML file.
landing = page.parent / 'index.html'
if landing.exists():
    landing.write_text(re.sub(r"game.src='[^']+'", "game.src='game.html?v=" + token + "'", landing.read_text()))
