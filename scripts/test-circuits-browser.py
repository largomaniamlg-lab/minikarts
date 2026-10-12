"""Choose all four real circuits and tournament mode through normal browser controls."""
import functools,http.server,threading,sys
from playwright.sync_api import sync_playwright
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=sys.argv[1]))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=browser.new_page(viewport={'width':640,'height':360});errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or (m.type=='error' and '404' not in m.text) else None)
  page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=120000)
  page.wait_for_timeout(700)
  for track in range(1,5):
   page.mouse.click(220,15);page.wait_for_timeout(250)
   page.mouse.click(220,33+13.5*track);page.wait_for_timeout(300)
   page.mouse.click(320,216)
   page.wait_for_timeout(1500)
   print("Circuit selection",track,page.evaluate("window.minikartsOfflineTest"),errors,flush=True)
   page.screenshot(path="/tmp/minikarts25-ui-before-race.png")
   page.wait_for_function('(id)=>window.minikartsOfflineTest?.track===id && window.minikartsOfflineTest.phase==="racing"',arg=track,timeout=45000)
   page.screenshot(path=f'/tmp/minikarts25-circuit-{track}.png')
   # Open the common menu then pilot/lap selection, without editing game state.
   page.mouse.click(523,20);page.wait_for_timeout(300);page.mouse.click(557,134)
   page.wait_for_function('!window.minikartsHudTest.rects.timing.visible')
  page.mouse.click(440,15);page.wait_for_timeout(250);page.mouse.click(440,47);page.wait_for_timeout(300)
  page.mouse.click(320,216)
  page.wait_for_function('window.minikartsOfflineTest?.tournament.enabled && window.minikartsOfflineTest.track===0 && window.minikartsOfflineTest.laps===3 && window.minikartsOfflineTest.phase==="racing"',timeout=45000)
  page.screenshot(path='/tmp/minikarts25-qualifying.png')
  assert not errors,errors
  print('PASS: four selected circuits render and race; tournament starts three-lap qualifying on original')
  browser.close()
finally:server.shutdown();server.server_close()
