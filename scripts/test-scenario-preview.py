"""Render real circuit geometry using an explicitly launched local overview fixture."""
import functools,http.server,threading,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
folder=Path(sys.argv[1]).resolve()
text=(folder/'game.html').read_text().replace('"args":["--","--force-touch"]','"args":["--script","res://tests/scenario_preview.gd","--","--force-touch"]')
(folder/'scenario-preview.html').write_text(text)
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(folder)))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=browser.new_page(viewport={'width':1280,'height':720});errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:(errors.append(m.text),print(m.text,flush=True)) if 'SCRIPT ERROR' in m.text or 'ERROR:' in m.text else None)
  page.goto(f'http://127.0.0.1:{server.server_port}/scenario-preview.html')
  page.locator('#status').wait_for(state='detached',timeout=120000)
  for id in range(1,5):
   page.evaluate('(id)=>window.nextScenario=id',id)
   page.wait_for_function('(id)=>window.scenarioPreview?.id===id',arg=id,timeout=30000)
   page.wait_for_timeout(1000)
   page.screenshot(path=f'/tmp/minikarts27-overview-{id}.png')
  assert not errors,errors
  print('PASS: four real themed circuits render via explicit overview fixture')
  browser.close()
finally:server.shutdown();server.server_close()
