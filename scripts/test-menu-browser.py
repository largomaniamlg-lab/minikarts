"""Exercise wizard resizing and room sharing using actual canvas controls."""
import functools,http.server,threading,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
folder=Path(sys.argv[1]).resolve()
(folder/'game-menu-test.html').write_text((folder/'game.html').read_text().replace('wss://minikarts-multiplayer.onrender.com','ws://127.0.0.1:8080'))
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(folder)))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=browser.new_page(viewport={'width':640,'height':360});errors=[]
  page.add_init_script("Object.defineProperty(navigator,'share',{value:async data=>{window.sharedRoom=data;}})")
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
  page.goto(f'http://127.0.0.1:{server.server_port}/game-menu-test.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=120000);page.wait_for_timeout(800)
  for width,height in [(640,360),(844,390),(1280,591)]:
   page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(350)
   scale=height/720;offset=(width-1280*scale)/2
   def click(x,y):
    page.mouse.click(x*scale+offset,y*scale);page.wait_for_timeout(250)
   page.screenshot(path=f'/tmp/minikarts26-menu-{width}.png')
   click(910,637);page.screenshot(path=f'/tmp/minikarts26-garage-{width}.png')
   click(910,637);page.screenshot(path=f'/tmp/minikarts26-summary-{width}.png')
   click(510,637);click(510,637)
  page.set_viewport_size({'width':640,'height':360});page.wait_for_timeout(300)
  page.mouse.click(505,118);page.wait_for_timeout(300)
  page.mouse.click(505,185);page.wait_for_timeout(300)
  for _ in range(3):page.mouse.click(455,318);page.wait_for_timeout(300)
  page.screenshot(path='/tmp/minikarts26-before-lobby.png')
  print('Lobby diagnostics',page.evaluate('window.minikartsLobbyTest'),flush=True)
  def tap(key):
   page.wait_for_function('(k)=>window.minikartsLobbyTest?.buttons[k]',arg=key)
   r=page.evaluate('(k)=>window.minikartsLobbyTest.buttons[k]',key)
   page.mouse.click((r['x']+r['width']/2)/2,(r['y']+r['height']/2)/2)
  tap('create')
  page.wait_for_function('window.minikartsLobbyTest.joined',timeout=30000)
  page.screenshot(path='/tmp/minikarts26-room.png')
  tap('share')
  page.wait_for_function('window.sharedRoom')
  code=page.evaluate('window.minikartsConnectionTest.room')
  assert page.evaluate('window.sharedRoom.url')=='https://largomaniamlg-lab.github.io/minikarts/prueba-grupo.html?room='+code
  assert not errors,errors
  print('PASS: three viewport sizes, wizard forward/back, actual room creation and share URL; native share dialog intercepted locally')
  browser.close()
finally:server.shutdown();server.server_close()
