"""Validate a local export without publishing or modifying repository files."""
import functools
import http.server
import sys
import threading
from pathlib import Path
from playwright.sync_api import sync_playwright

directory = Path(sys.argv[1]).resolve()
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(directory))
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        page = browser.new_page(viewport={'width': 1280, 'height': 720})
        errors = []
        responses = {}
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('response', lambda response: responses.update({response.url.split('/')[-1]: response.status}))
        page.goto(f'http://127.0.0.1:{server.server_port}/')
        page.click('#play')
        frame = page.frame_locator('#game')
        frame.locator('#canvas').wait_for()
        frame.locator('#status').wait_for(state='detached', timeout=60000)
        assert frame.locator('#canvas').evaluate('(c) => c.width > 0 && c.height > 0')
        page.wait_for_timeout(1000)
        assert not errors, errors
        for asset in ['game.js', 'game.pck', 'game.wasm.gz']:
            assert responses.get(asset) == 200, (asset, responses)
        assert frame.locator('body').evaluate('() => GODOT_CONFIG.args[0] === "--" && GODOT_CONFIG.args[1] === "--force-touch"')
        page.screenshot(path='/tmp/minikarts-touch-check.png')
        page.click('#back')
        assert not page.locator('body').evaluate('(b) => b.classList.contains("playing")')
        browser.close()
        print('PASS: exportación web arranca, assets 200, controles táctiles configurados y retorno correcto')
finally:
    server.shutdown()
    server.server_close()
