"""Check room-code validation, automatic retries and successful manual retry after recovery."""
import functools,http.server,threading,subprocess,os,sys,time
from pathlib import Path
from playwright.sync_api import sync_playwright
from browser_lobby import tap_control
repo=Path(__file__).resolve().parents[1]
web=Path(sys.argv[1]);pagefile=web/'game.html';original=pagefile.read_text();server_process=None
http=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(web)))
threading.Thread(target=http.serve_forever,daemon=True).start()
try:
 pagefile.write_text(original.replace('wss://minikarts-multiplayer.onrender.com','ws://127.0.0.1:18089'))
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  page=browser.new_page(viewport={'width':640,'height':360},has_touch=True,is_mobile=True)
  page.goto(f'http://127.0.0.1:{http.server_port}/game.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=180000)
  page.touchscreen.tap(320,232)
  page.wait_for_function("window.minikartsConnectionTest && !window.minikartsConnectionTest.connecting && window.minikartsConnectionTest.message.includes(\"tras tres intentos\")",timeout=40000)
  tap_control(page, "manual")
  tap_control(page, "join")
  page.wait_for_function('window.minikartsConnectionTest && window.minikartsConnectionTest.message.includes("seis caracteres")',timeout=10000)
  print('PASS: empty room code explains required format',flush=True)
  tap_control(page, "create")
  page.wait_for_function('window.minikartsConnectionTest.message.includes("tras tres intentos")',timeout=40000)
  assert not page.evaluate('window.minikartsConnectionTest.connecting')
  print('PASS: three automatic attempts against unavailable server, actionable final error',flush=True)
  log=open('/tmp/minikarts-room-retry-server.log','w')
  server_process=subprocess.Popen(['bash','scripts/server.sh','--preimported'],cwd=repo,env=dict(os.environ,PORT='18089'),stdout=log,stderr=subprocess.STDOUT)
  time.sleep(1)
  page.screenshot(path="/tmp/minikarts-room-retry-before.png")
  tap_control(page, "create")
  try:
   page.wait_for_function('window.minikartsTest && window.minikartsTest.state.players.length === 1',timeout=30000)
  except Exception:
   print(page.evaluate('window.minikartsConnectionTest'),flush=True)
   page.screenshot(path='/tmp/minikarts-room-retry-failed.png')
   raise
  print('PASS: same Create button retries successfully after server returns',flush=True)
  page.screenshot(path='/tmp/minikarts-room-retry-success.png')
  browser.close()
finally:
 pagefile.write_text(original)
 if server_process:server_process.terminate();server_process.wait(timeout=10)
 http.shutdown()
