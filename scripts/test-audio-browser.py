"""Exercise actual WebAudio output, tactile mixer and offline race audio."""
import functools,http.server,threading,sys
from playwright.sync_api import sync_playwright
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=sys.argv[1]))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--autoplay-policy=user-gesture-required'])
  page=browser.new_page(viewport={'width':640,'height':360},has_touch=True,is_mobile=True)
  errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or 'ERROR:' in m.text else None)
  page.add_init_script('''window.audioMeters=[];const originalConnect=AudioNode.prototype.connect;AudioNode.prototype.connect=function(target,...args){if(target instanceof AudioDestinationNode){const meter=this.context.createAnalyser();meter.fftSize=512;originalConnect.call(this,meter);window.audioMeters.push(meter);}return originalConnect.call(this,target,...args);};window.audioEnergy=()=>Math.max(0,...window.audioMeters.map(m=>{let a=new Float32Array(m.fftSize);m.getFloatTimeDomainData(a);return Math.max(...a.map(Math.abs));}));''')
  page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=180000)
  page.touchscreen.tap(300,90)
  page.wait_for_function('window.minikartsAudioTest && window.minikartsAudioTest.music',timeout=30000)
  page.wait_for_function('window.audioEnergy() > 0.001',timeout=20000)
  print('PASS: music produces nonzero WebAudio PCM after touch',flush=True)
  page.touchscreen.tap(50,90)
  page.wait_for_timeout(500)
  page.touchscreen.tap(13,147)
  page.wait_for_function('window.minikartsAudioTest.music_volume === 0')
  page.wait_for_timeout(700)
  assert page.evaluate('window.audioEnergy()') < .001
  page.touchscreen.tap(55,147)
  page.wait_for_function('window.minikartsAudioTest.music_volume > 0')
  page.touchscreen.tap(13,180)
  page.wait_for_function('window.minikartsAudioTest.effects_volume === 0')
  page.touchscreen.tap(85,180)
  page.wait_for_function('window.minikartsAudioTest.effects_volume > 0')
  print('PASS: independent music/effects sliders',flush=True)
  page.touchscreen.tap(70,120)
  page.wait_for_function('window.minikartsAudioTest.muted')
  page.wait_for_timeout(1000)
  assert page.evaluate('window.audioEnergy()') < .001
  print('PASS: mute produces silence',flush=True)
  page.touchscreen.tap(70,120)
  page.wait_for_function('!window.minikartsAudioTest.muted')
  page.wait_for_function('window.audioEnergy() > .001')
  page.touchscreen.tap(50,90)
  page.touchscreen.tap(320,195)
  page.wait_for_function('window.minikartsOfflineTest && window.minikartsOfflineTest.phase === "racing"',timeout=30000)
  page.wait_for_function('window.minikartsAudioTest.engine && window.minikartsAudioTest.pitch > 1',timeout=20000)
  data=page.evaluate('window.minikartsAudioTest')
  assert data['events'].get('tick',0)>=2,data
  assert data['events'].get('go',0)==1,data
  page.touchscreen.tap(600,325)
  page.wait_for_function('window.minikartsAudioTest.events.shoot > 0',timeout=15000)
  assert not errors,errors
  page.screenshot(path='/tmp/minikarts-audio-race.png')
  print('PASS: countdown, start, accelerating engine and shot; no browser errors',flush=True)
  browser.close()
finally: server.shutdown()
