"""Verify multiplayer through ordered, delayed WebSocket links (120–240 ms injected round-trip delay).

Usage: python3 scripts/test-network-delay.py /tmp/minikarts-web.EXPORT
Only the supplied temporary export is rewritten, then restored.
"""
import asyncio, os, subprocess, sys, re
from pathlib import Path
import websockets
repo=Path(__file__).resolve().parents[1]
web=Path(sys.argv[1]).resolve() / 'game.html'
async def relay(source,target):
    queue=asyncio.Queue(maxsize=128)
    async def read():
        last=0; index=0
        async for message in source:
            now=asyncio.get_running_loop().time()
            due=max(last,now+[.06,.10,.08,.12][index%4]); last=due;index+=1
            await queue.put((due,message))
        await queue.put(None)
    async def write():
        while True:
            item=await queue.get()
            if item is None:return
            due,message=item
            await asyncio.sleep(max(0,due-asyncio.get_running_loop().time()))
            await target.send(message)
    jobs=[asyncio.create_task(read()),asyncio.create_task(write())]
    try:await asyncio.gather(*jobs)
    finally:
        for job in jobs:job.cancel()
async def proxy(client):
    try:
        async with websockets.connect('ws://127.0.0.1:18087',close_timeout=1) as upstream:
            jobs=[asyncio.create_task(relay(client,upstream)),asyncio.create_task(relay(upstream,client))]
            try:await asyncio.wait(jobs,return_when=asyncio.FIRST_COMPLETED)
            finally:
                for job in jobs:job.cancel()
                await asyncio.gather(*jobs,return_exceptions=True)
    except websockets.exceptions.ConnectionClosed:pass
async def main():
    original=web.read_text()
    with open('/tmp/minikarts-motion-server.log','w') as log:
        server=subprocess.Popen(['bash','scripts/server.sh','--preimported'],cwd=repo,env=dict(os.environ,PORT='18087'),stdout=log,stderr=subprocess.STDOUT)
        try:
            for i in range(50):
                if server.poll() is not None:
                    raise RuntimeError("Owned test server exited; inspect /tmp/minikarts-motion-server.log")
                try:
                    reader,writer=await asyncio.open_connection('127.0.0.1',18087);writer.close();await writer.wait_closed();break
                except OSError:await asyncio.sleep(.1)
            else:
                raise RuntimeError("Owned test server did not become ready")
            async with websockets.serve(proxy,'127.0.0.1',18088):
                configured, count = re.subn(r'window\.MINIKARTS_SERVER_URL = [^;]*;', 'window.MINIKARTS_SERVER_URL = "ws://127.0.0.1:18088";', original)
                if count != 1:
                    raise RuntimeError('Missing server URL setting in temporary export')
                web.write_text(configured)
                for args in [['python3','scripts/test-multiplayer.py','ws://127.0.0.1:18088'],['python3','scripts/test-multiplayer-browser.py',str(web.parent)]]:
                    await asyncio.to_thread(subprocess.run,args,cwd=repo,check=True)
                print('PASS: protocolo y cuatro navegadores con 60–120 ms variables en cada sentido',flush=True)
        finally:
            web.write_text(original);server.terminate();server.wait(timeout=10)
asyncio.run(main())
