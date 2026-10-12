"""Render sixteen racers in Chromium: one browser and fifteen WebSocket peers."""
import asyncio,functools,http.server,threading,json,websockets,sys,os
from pathlib import Path
from playwright.async_api import async_playwright
async def receive(ws,kind):
 async with asyncio.timeout(15):
  while True:
   m=json.loads(await ws.recv())
   if m['type']==kind:return m
async def send(ws,**m):await ws.send(json.dumps(m))
async def tap(page,key):
 await page.wait_for_function('(k)=>window.minikartsLobbyTest?.buttons[k]',arg=key)
 r=await page.evaluate('(k)=>window.minikartsLobbyTest.buttons[k]',key)
 await page.mouse.click((r['x']+r['width']/2)/2,(r['y']+r['height']/2)/2)
async def main():
 directory=Path(sys.argv[1]).resolve()
 test_page=directory / "game-ten-test.html"
 test_page.write_text((directory / "game.html").read_text().replace("wss://minikarts-multiplayer.onrender.com", "ws://127.0.0.1:8080"))
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(directory)))
 threading.Thread(target=server.serve_forever,daemon=True).start();clients=[];errors=[]
 try:
  for i in range(15):
   ws=await websockets.connect('ws://127.0.0.1:8080',max_queue=None,close_timeout=1);clients.append(ws)
   await send(ws,type='create' if i==0 else 'join',code='' if i==0 else code,name=f'Prueba {i+1}',driver=i, laps=6, track=int(os.environ.get('MINIKARTS_TEST_TRACK','0')))
   code=(await receive(ws,'welcome'))['code']
  async with async_playwright() as p:
   browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
   page=await browser.new_page(viewport={'width':640,'height':360})
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or (m.type=='error' and '404' not in m.text) else None)
   await page.goto(f'http://127.0.0.1:{server.server_port}/game-ten-test.html?test=1')
   await page.locator('#status').wait_for(state='detached',timeout=120000)
   await page.mouse.click(505,185) # Friends
   await page.mouse.click(455,318);await page.wait_for_timeout(250)
   for _ in range(2):
    await page.mouse.click(605,145);await page.wait_for_timeout(200)
   await page.mouse.click(278,145)
   for _ in range(2):
    await page.mouse.click(455,318);await page.wait_for_timeout(250)
   await tap(page,'room_'+code)
   await page.wait_for_function('window.minikartsTest?.rendered_karts===16',timeout=30000)
   await page.screenshot(path='/tmp/minikarts-ten-lobby.png')
   await tap(page,'ready')
   for ws in clients:await send(ws,type='ready',ready=True)
   await asyncio.sleep(.5);await send(clients[0],type='start')
   await page.wait_for_function('window.minikartsTest?.state.phase==="racing"',timeout=30000)
   for _ in range(25):
    for ws in clients:await send(ws,type='input',controls={'accelerate':1})
    await asyncio.sleep(.05)
   assert await page.evaluate('window.minikartsTest.physics_interpolation === false'), 'Online poses must not be interpolated a second time'
   await page.wait_for_function('window.minikartsHudTest?.rects.timing.visible && window.minikartsHudTest.rects.timing.height<=66')
   await page.screenshot(path='/tmp/minikarts-ten-race.png')
   state=await page.evaluate('window.minikartsTest')
   assert state['rendered_karts']==16 and len(state['state']['players'])==16
   assert state['state']['laps']==6
   assert not errors,errors
   await browser.close();print('PASS: browser joins fifteen WebSocket peers via room list, renders sixteen karts and runs race without script errors')
 finally:
  for ws in clients:await ws.close()
  server.shutdown();server.server_close();test_page.unlink(missing_ok=True)
asyncio.run(main())
