"""Exercise WebAudio PCM, themed-circuit switching and the current tactile mixer."""
import functools,http.server,threading,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=sys.argv[1]))
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--autoplay-policy=user-gesture-required'])
  page=browser.new_page(viewport={'width':640,'height':360},has_touch=True,is_mobile=True);errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or 'ERROR:' in m.text else None)
  page.add_init_script('''window.audioMeters=[];const originalConnect=AudioNode.prototype.connect;AudioNode.prototype.connect=function(target,...args){if(target instanceof AudioDestinationNode){const meter=this.context.createAnalyser();meter.fftSize=512;originalConnect.call(this,meter);window.audioMeters.push(meter);}return originalConnect.call(this,target,...args);};window.audioEnergy=()=>Math.max(0,...window.audioMeters.map(m=>{let a=new Float32Array(m.fftSize);m.getFloatTimeDomainData(a);return Math.max(...a.map(Math.abs));}));''')
  page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
  page.locator('#status').wait_for(state='detached',timeout=120000)
  page.touchscreen.tap(455,318);page.wait_for_timeout(250)
  page.touchscreen.tap(350,242);page.wait_for_timeout(250);page.touchscreen.tap(350,282);page.wait_for_timeout(250)
  for _ in range(2):page.touchscreen.tap(455,318);page.wait_for_timeout(300)
  page.wait_for_function('window.minikartsOfflineTest?.phase==="racing" && window.minikartsAudioTest?.circuit===1',timeout=30000)
  expected='velocity_music.ogg' if (Path(__file__).resolve().parents[1]/'godot/assets/audio/velocity_music.ogg').exists() else 'race_music.ogg'
  assert page.evaluate('minikartsAudioTest.track').endswith(expected)
  page.wait_for_function('window.audioEnergy()>.001')
  page.touchscreen.tap(523,20);page.wait_for_timeout(250);page.touchscreen.tap(555,161);page.wait_for_timeout(300)
  def slider(key,value):
   r=page.evaluate('(k)=>minikartsAudioTest.mixer[k]',key)
   page.touchscreen.tap((r['x']+8+(r['width']-16)*value)/2,(r['y']+r['height']/2)/2)
   page.wait_for_timeout(250)
  slider('EffectsVolume',0);page.wait_for_function('minikartsAudioTest.effects_volume===0')
  slider('MusicVolume',0);page.wait_for_function('minikartsAudioTest.music_volume===0')
  page.wait_for_timeout(700);assert page.evaluate('audioEnergy()')<.001
  slider('MusicVolume',.5);page.wait_for_function('audioEnergy()>.001')
  slider('EffectsVolume',.7);page.wait_for_function('minikartsAudioTest.effects_volume>0')
  def mute():
   r=page.evaluate('minikartsAudioTest.mixer.mute');page.touchscreen.tap((r['x']+r['width']/2)/2,(r['y']+r['height']/2)/2)
  mute();page.wait_for_function('minikartsAudioTest.muted');page.wait_for_timeout(700)
  assert page.evaluate('audioEnergy()')<.001
  mute();page.wait_for_function('!minikartsAudioTest.muted && audioEnergy()>.001')
  page.touchscreen.tap(523,20);page.wait_for_timeout(250);page.touchscreen.tap(523,20);page.wait_for_timeout(250)
  page.touchscreen.tap(589,309)
  page.wait_for_function('minikartsAudioTest.events.shoot>0')
  assert not errors,errors
  print('PASS: themed circuit audio/fallback, real PCM, independent mixer, mute and firing')
  browser.close()
finally:server.shutdown();server.server_close()
