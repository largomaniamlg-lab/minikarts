"""Exercise tournament creation, qualifying, four stages and final podium over real local WebSockets.
Uses an explicitly launched local gate-transition fixture, not a production cheat endpoint.
"""
import asyncio,functools,http.server,threading,json,os,sys,subprocess
from pathlib import Path
import websockets
from playwright.async_api import async_playwright
repo=Path(__file__).resolve().parents[1]
async def send(ws,**m):await ws.send(json.dumps(m))
async def receive(ws,kind):
 async with asyncio.timeout(15):
  while True:
   m=json.loads(await ws.recv())
   if m['type']==kind:return m
async def tap(page,key):
 await page.wait_for_function('(k)=>window.minikartsLobbyTest?.buttons[k]',arg=key)
 r=await page.evaluate('(k)=>window.minikartsLobbyTest.buttons[k]',key)
 await page.mouse.click((r['x']+r['width']/2)/2,(r['y']+r['height']/2)/2)
async def main():
 directory=Path(sys.argv[1]).resolve();test_page=directory/'game-tournament-test.html'
 test_page.write_text((directory/'game.html').read_text().replace('wss://minikarts-multiplayer.onrender.com','ws://127.0.0.1:18089'))
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(directory)))
 threading.Thread(target=server.serve_forever,daemon=True).start()
 log=open('/tmp/minikarts25-tournament-fixture.log','w')
 engine=os.environ.get('GODOT_BIN','/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64')
 env=dict(os.environ,PORT='18089',XDG_CACHE_HOME='/workspace/.minikarts-cache',XDG_DATA_HOME='/workspace/.minikarts-data',XDG_CONFIG_HOME='/workspace/.minikarts-config')
 backend=subprocess.Popen([engine,'--headless','--path',str(repo/'godot'),'--script','tests/tournament_web_fixture.gd','--','--server'],env=env,stdout=log,stderr=subprocess.STDOUT)
 peers=[];errors=[]
 try:
  for _ in range(50):
   try:
    r,w=await asyncio.open_connection('127.0.0.1',18089);w.close();await w.wait_closed();break
   except OSError:await asyncio.sleep(.1)
  async with async_playwright() as p:
   browser=await p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
   page=await browser.new_page(viewport={'width':640,'height':360})
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or (m.type=='error' and '404' not in m.text) else None)
   await page.goto(f'http://127.0.0.1:{server.server_port}/game-tournament-test.html?test=1')
   await page.locator('#status').wait_for(state='detached',timeout=120000)
   await page.wait_for_timeout(700)
   await page.mouse.click(505,118) # Tournament
   await page.mouse.click(505,185) # Friends
   for _ in range(3):
    await page.mouse.click(455,318);await page.wait_for_timeout(250)
   await tap(page,'create')
   await page.wait_for_function('window.minikartsTest?.state.tournament.enabled && window.minikartsTest.state.phase==="lobby"',timeout=30000)
   code=await page.evaluate('window.minikartsTest.state.code')
   for index in range(2):
    ws=await websockets.connect('ws://127.0.0.1:18089',close_timeout=1,max_queue=None);peers.append(ws)
    await send(ws,type='join',code=code,name=f'Amigo {index+1}',driver=index+1)
    await receive(ws,'welcome')
   await page.wait_for_function('window.minikartsTest.state.players.length===3')
   for stage in range(5):
    print('Testing tournament stage',stage,flush=True)
    for ws in peers:await send(ws,type='ready',ready=True)
    await tap(page,'ready')
    await page.wait_for_function('window.minikartsTest.state.players.every(p=>p.ready)')
    await tap(page,'start')
    await page.wait_for_function('window.minikartsTest.state.phase==="racing"')
    await page.mouse.click(523,20);await page.wait_for_timeout(350)
    await page.mouse.click(555,161)
    await page.wait_for_function('window.minikartsAudioTest?.mixer_visible===true')
    await page.wait_for_function('(s)=>window.minikartsTest.state.phase==="results" && window.minikartsTest.state.tournament.stage===s',arg=stage,timeout=60000)
    await page.wait_for_timeout(700)
    assert await page.evaluate('minikartsAudioTest.mixer_visible') is False, 'Audio mixer must close at results'
    state=await page.evaluate('window.minikartsTest.state')
    assert state['track']==stage and state['laps']==3,state
    await page.screenshot(path=f'/tmp/minikarts25-tournament-stage-{stage}.png')
    if stage<4:
     await tap(page,'start')
     await page.wait_for_function('(s)=>window.minikartsTest.state.phase==="lobby" && window.minikartsTest.state.tournament.stage===s',arg=stage+1)
   assert state['tournament']['finished'] and len(state['tournament']['standings'])==3,state
   assert not errors,errors
   print('PASS: real browser creates tournament, advances qualifying and four circuit stages; final podium renders without script errors')
   await browser.close()
 finally:
  for ws in peers:await ws.close()
  backend.terminate();backend.wait(timeout=10);log.close()
  server.shutdown();server.server_close();test_page.unlink(missing_ok=True)
asyncio.run(main())
