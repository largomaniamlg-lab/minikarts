"""Connect four actual Web exports to the local Godot server via their lobby UI."""
import functools
import http.server
import sys
import threading
from playwright.sync_api import sync_playwright

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
            page.wait_for_timeout(600)
            click(page, 450, 202)  # Nombre
            page.wait_for_timeout(500)
            page.keyboard.press('Control+a')
            page.keyboard.type(f'Amigo {index + 1}', delay=100)
            if index:
                click(page, 450, 255)
                page.wait_for_timeout(500)
                page.keyboard.type(code, delay=100)
                click(page, 475, 308)  # Unirse
            else:
                click(page, 370, 308)  # Crear
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
            click(page, 600, 452)  # Listo: four racers expand the lobby header
        pages[0].wait_for_function('window.minikartsTest.state.players.every(p => p.ready)', timeout=20000)
        pages[0].screenshot(path='/tmp/minikarts-four-player-lobby.png')
        click(pages[0], 600, 505)  # Iniciar
        for page in pages:
            page.wait_for_function('window.minikartsTest.state.phase === "racing"', timeout=15000)
        pages[0].wait_for_function('window.minikartsTest.state.elapsed > 2', timeout=10000)
        assert not errors, errors
        pages[0].screenshot(path='/tmp/minikarts-four-player-race.png')
        print('PASS: cuatro clientes Chromium crean/unifican sala, muestran 4 karts y arrancan la carrera sincronizada')
        browser.close()
finally:
    server.shutdown()
    server.server_close()
