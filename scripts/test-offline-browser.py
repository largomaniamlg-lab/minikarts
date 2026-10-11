"""Exercise visual pilot selection and a solo race with three real bots in Chromium."""
import functools
import http.server
import sys
import threading
from playwright.sync_api import sync_playwright

server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(
    http.server.SimpleHTTPRequestHandler, directory=sys.argv[1]))
threading.Thread(target=server.serve_forever, daemon=True).start()
errors = []
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        page = browser.new_page(viewport={'width': 640, 'height': 360}, has_touch=True, is_mobile=True)
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('console', lambda message: errors.append(message.text)
            if 'SCRIPT ERROR' in message.text or 'ERROR:' in message.text else None)
        page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
        page.locator('#status').wait_for(state='detached', timeout=180000)
        page.wait_for_timeout(1500)
        page.screenshot(path='/tmp/minikarts-character-menu.png')
        page.mouse.click((345 + 3 * 195) / 2, 210 / 2)
        page.mouse.click(640 / 2, 432 / 2)
        page.wait_for_function('window.minikartsOfflineTest && window.minikartsOfflineTest.phase === "racing"', timeout=30000)
        page.wait_for_function('window.minikartsOfflineTest.elapsed > 3', timeout=15000)
        assert len(page.evaluate('window.minikartsOfflineTest.racers')) == 4
        assert not errors, errors
        page.screenshot(path='/tmp/minikarts-offline-bots.png')
        browser.close()
        print('PASS: menú visual, selección de personaje y carrera offline con tres bots arrancan en Chromium táctil')
finally:
    server.shutdown()
    server.server_close()
