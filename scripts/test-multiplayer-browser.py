"""Connect four actual Web exports to the local Godot server via their lobby UI."""
import functools
import http.server
import sys
import threading
from playwright.sync_api import sync_playwright
from browser_lobby import tap_control, wait_connected

directory = sys.argv[1]
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0),
    functools.partial(http.server.SimpleHTTPRequestHandler, directory=directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
errors = []

def click(page, x, y):
    # Keep Godot's logical 1280x720 coordinates while reducing software GPU load.
    page.mouse.click(x / 2, y / 2)
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--disable-background-timer-throttling', '--disable-renderer-backgrounding'])
        pages = []
        for index in range(4):
            page = browser.new_page(viewport={'width': 640, 'height': 360}, has_touch=True, is_mobile=True)
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.on('console', lambda message: errors.append(message.text)
                if 'SCRIPT ERROR' in message.text or 'ERROR:' in message.text else None)
            page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
            page.locator('#status').wait_for(state='detached', timeout=180000)
            page.wait_for_timeout(1200)
            click(page, 345 + index * 195, 210)  # Visual portrait selection.
            click(page, 640, 465)  # Online mode.
            wait_connected(page)
            tap_control(page, 'name')
            page.keyboard.press('Control+a')
            page.keyboard.type(f'Amigo {index + 1}', delay=50)
            if index:
                page.wait_for_function('(code) => window.minikartsLobbyTest.rooms.some(r => r.code === code)',arg=code,timeout=15000)
                tap_control(page, 'room_' + code)
            else:
                tap_control(page, 'create')
            try:
                page.wait_for_function('window.minikartsTest && window.minikartsTest.state.players.length > 0', timeout=30000)
            except Exception:
                page.screenshot(path='/tmp/minikarts-lobby-failed.png')
                print('Browser errors:', errors)
                raise
            code = page.evaluate('window.minikartsTest.state.code')
            pages.append(page)
        for page in pages:
            page.wait_for_function('window.minikartsTest.rendered_karts === 4', timeout=20000)
            assert {r['driver'] for r in page.evaluate('window.minikartsTest.state.players')} == {0, 1, 2, 3}
            assert 'create' not in page.evaluate('window.minikartsLobbyTest.buttons')
            tap_control(page, 'ready')
        pages[0].wait_for_function('window.minikartsTest.state.players.every(p => p.ready)', timeout=20000)
        pages[0].screenshot(path='/tmp/minikarts-four-player-lobby.png')
        tap_control(pages[0], 'start')
        for page in pages:
            page.wait_for_function('window.minikartsTest.state.phase === "racing"', timeout=15000)
        pages[0].wait_for_function('window.minikartsTest.state.elapsed > 2', timeout=10000)
        assert not errors, errors
        pages[0].screenshot(path='/tmp/minikarts-four-player-race.png')
        print('PASS: cuatro clientes Chromium crean y seleccionan sala sin códigos, muestran 4 karts y arrancan sincronizados')
        browser.close()
finally:
    server.shutdown()
    server.server_close()
