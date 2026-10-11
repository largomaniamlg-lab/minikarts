"""Deliver five real browser touch contacts to the exported Godot canvas."""
import functools, http.server, threading, sys
from playwright.sync_api import sync_playwright
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=sys.argv[1]))
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        page = browser.new_page(viewport={'width':1280,'height':720}, has_touch=True)
        errors=[]
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
        page.goto(f'http://127.0.0.1:{server.server_port}/game.html?test=1')
        page.locator('#status').wait_for(state='detached',timeout=120000)
        page.wait_for_timeout(700)
        page.mouse.click(640,432)
        page.wait_for_function('window.minikartsTouchTest !== undefined')
        print('Initial touch diagnostics:', page.evaluate('minikartsTouchTest'), flush=True)
        cdp=page.context.new_cdp_session(page)
        points={0:(185,580),1:(1102,464),2:(1178,618),3:(1026,618),4:(1178,618)}
        def dispatch(kind, contacts=None):
            cdp.send('Input.dispatchTouchEvent',{'type':kind,'touchPoints':[
                {'id':i,'x':xy[0],'y':xy[1],'radiusX':2,'radiusY':2,'force':1} for i,xy in (points if contacts is None else contacts).items()]})
        dispatch('touchStart')
        page.wait_for_timeout(500)
        print('Pressed touch diagnostics:',page.evaluate('minikartsTouchTest'),flush=True)
        page.wait_for_function('minikartsTouchTest.contacts===5 && ["steer_right","brake","jump","shoot"].every(a=>minikartsTouchTest.actions[a]>0)')
        strength=page.evaluate('minikartsTouchTest.actions.steer_right')
        points[0]=(185,420);points[2]=(640,300)
        dispatch('touchMove')
        page.wait_for_timeout(350)
        assert abs(page.evaluate('minikartsTouchTest.actions.steer_right')-strength)<.001
        assert page.evaluate('minikartsTouchTest.actions.shoot')==1
        released={2:points.pop(2)};dispatch('touchEnd',released)
        page.wait_for_timeout(400)
        print('First release:',page.evaluate('minikartsTouchTest'),flush=True)
        page.wait_for_function('minikartsTouchTest.contacts===4 && minikartsTouchTest.actions.shoot===1')
        released={4:points.pop(4)};dispatch('touchEnd',released)
        page.wait_for_timeout(400)
        print('Last shoot release:',page.evaluate('minikartsTouchTest'),flush=True)
        page.wait_for_function('minikartsTouchTest.contacts===3 && minikartsTouchTest.actions.shoot===0 && minikartsTouchTest.actions.brake===1')
        points.clear();dispatch('touchCancel')
        page.wait_for_function('minikartsTouchTest.contacts===0 && Object.values(minikartsTouchTest.actions).every(x=>x===0)')
        assert not errors, errors
        browser.close()
        print('PASS: five browser contacts, independent actions, vertical drift, shared button, release and cancel')
finally:
    server.shutdown();server.server_close()
