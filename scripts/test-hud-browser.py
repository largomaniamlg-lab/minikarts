"""Check racing HUD bounds and its menu on three landscape screen shapes."""
import functools, http.server, threading, sys
from playwright.sync_api import sync_playwright
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=sys.argv[1]))
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
 with sync_playwright() as p:
  browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
  for width, height in [(640,360),(1280,591),(844,390)]:
   errors = []
   page = browser.new_page(viewport={'width':width,'height':height})
   page.on('pageerror', lambda e: errors.append(str(e)))
   page.on('console', lambda m: errors.append(m.text) if 'SCRIPT ERROR' in m.text or (m.type == 'error' and '404' not in m.text) else None)
   page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
   page.locator('#status').wait_for(state='detached', timeout=120000)
   page.wait_for_function('window.minikartsHudTest?.viewport')
   def click(x,y):
    viewport = page.evaluate('window.minikartsHudTest.viewport')
    page.mouse.click(x*width/viewport[0],y*height/viewport[1])
   click(640,432)
   page.wait_for_function('window.minikartsOfflineTest?.phase === "racing"', timeout=45000)
   hud = page.evaluate('window.minikartsHudTest')
   timing, menu = hud['rects']['timing'], hud['rects']['menu']
   assert timing['visible'] and timing['height'] <= 66, hud
   assert '\n' not in hud['text'] and 'PUESTO' in hud['text'], hud
   assert timing['x'] >= 0 and timing['x']+timing['width'] <= hud['viewport'][0], hud
   assert timing['x']+timing['width'] < menu['x'], hud
   assert not hud['rects']['options']['visible'], hud
   page.screenshot(path=f'/tmp/minikarts23-hud-{width}x{height}.png')
   click(menu['x']+menu['width']/2, menu['y']+menu['height']/2)
   page.wait_for_function('window.minikartsHudTest.rects.options.visible')
   options = page.evaluate('window.minikartsHudTest.rects.options')
   assert options['y']+options['height'] < 408, options
   page.screenshot(path=f'/tmp/minikarts23-menu-{width}x{height}.png')
   click(options['x']+options['width']/2, options['y']+32)
   page.wait_for_function('!window.minikartsHudTest.rects.options.visible')
   assert not errors, errors
   print(f'PASS {width}x{height}: compact racing HUD, separate menu and working recovery')
   page.close()
  browser.close()
finally:
 server.shutdown(); server.server_close()
