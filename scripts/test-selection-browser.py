"""Exercise four portrait pages and choose nine laps with fifteen bots through the UI."""
import functools,http.server,threading,sys
from playwright.sync_api import sync_playwright
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=sys.argv[1]))
threading.Thread(target=server.serve_forever,daemon=True).start();errors=[]
try:
 with sync_playwright() as p:
  b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=b.new_page(viewport={'width':640,'height':360})
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
  page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=120000)
  page.wait_for_timeout(800)
  page.mouse.click(455,318);page.wait_for_timeout(250)
  for i in range(4):
   page.screenshot(path=f'/tmp/minikarts17-selection-{i+1}.png')
   if i<3:page.mouse.click(605,145);page.wait_for_timeout(250)
  page.mouse.click(545,145)
  for x in [300,500]:
   page.mouse.click(x,272);page.wait_for_timeout(200)
   page.mouse.click(x,330);page.wait_for_timeout(250)
  page.screenshot(path="/tmp/minikarts17-options.png")
  page.mouse.click(455,318);page.wait_for_timeout(200)
  page.mouse.click(455,318)
  page.wait_for_timeout(2000)
  page.screenshot(path="/tmp/minikarts17-start.png")
  page.wait_for_function('window.minikartsOfflineTest?.laps===9 && window.minikartsOfflineTest.racers.length===16',timeout=30000)
  page.wait_for_function('window.minikartsOfflineTest.phase==="racing"',timeout=30000)
  page.screenshot(path='/tmp/minikarts17-offline13.png')
  assert not errors,errors
  print('PASS: four character pages, final character, lap selector 9 and 15 bots through real menu controls')
  b.close()
finally:server.shutdown();server.server_close()
