"""Exercise the real WebSocket server with four independent connections."""
import asyncio
import json
import sys
import websockets

async def receive(ws, kind, predicate=lambda m: True):
    async with asyncio.timeout(10):
        while True:
            message = json.loads(await ws.recv())
            if message['type'] == kind and predicate(message):
                return message

async def send(ws, **message):
    await ws.send(json.dumps(message))

async def main():
    url = sys.argv[1] if len(sys.argv) > 1 else 'ws://127.0.0.1:8080'
    clients = []
    try:
        for index in range(4):
            ws = await websockets.connect(url)
            clients.append(ws)
            await send(ws, type='list')
            directory = await receive(ws, 'rooms')
            if index:
                selected = next(r for r in directory['rooms'] if r['code'] == code)
                assert selected['players'] == index and selected['host'] == 'Amigo 1'
                code = selected['code']
            await send(ws, type='create' if index == 0 else 'join', code='' if index == 0 else code, name=f'Amigo {index + 1}', driver=index)
            welcome = await receive(ws, 'welcome')
            code = welcome['code']
        state = await receive(clients[0], 'state', lambda m: len(m['players']) == 4)
        assert len({p['id'] for p in state['players']}) == 4
        assert len(state['boxes']) == 8
        assert {p['driver'] for p in state['players']} == {0, 1, 2, 3}
        assert len(state['neutral']) == 3
        async with websockets.connect(url) as extra:
            await send(extra, type='list')
            directory = await receive(extra, 'rooms')
            assert not any(r['code'] == code for r in directory['rooms']), 'Full rooms hidden'
            await send(extra, type='join', code=code, name='Quinto')
            error = await receive(extra, 'error')
            assert 'llena' in error['message']
        await send(clients[1], type='start')
        assert 'creador' in (await receive(clients[1], 'error'))['message']
        await send(clients[0], type='start')
        assert 'Listo' in (await receive(clients[0], 'error'))['message']
        for ws in clients:
            await send(ws, type='ready', ready=True)
        await receive(clients[0], 'state', lambda m: all(p['ready'] for p in m['players']))
        await send(clients[0], type='start')
        state = await receive(clients[0], 'state', lambda m: m['phase'] == 'countdown')
        assert all(abs(p['speed']) < 0.01 for p in state['players'])
        state = await receive(clients[0], 'state', lambda m: m['phase'] == 'racing')
        origins = {p['id']: p['position'] for p in state['players']}
        for _ in range(20):
            for ws in clients:
                await send(ws, type='input', controls={'accelerate': 1, 'shoot': 1}, lap=3, position=[999,999,999])
            await asyncio.sleep(.05)
        state = await receive(clients[0], 'state', lambda m: m['elapsed'] > .8)
        assert all(p['lap'] == 0 for p in state['players']), 'Client cannot forge laps'
        assert all(p['position'][0] < 100 for p in state['players']), 'Client cannot teleport'
        assert any(p['position'] != origins[p['id']] for p in state['players'])
        assert any(p['speed'] > 1 for p in state['players'])
        host = state['host']
        await clients[0].close()
        state = await receive(clients[1], 'state', lambda m: len(m['players']) == 3)
        assert state['host'] != host, 'Host migration after disconnect'
        print('PASS: listado y entrada por selección, 4 clientes, capacidad, autoridad, listos, cuenta atrás, movimiento, disparos solicitados y desconexión')
    finally:
        for ws in clients:
            await ws.close()

asyncio.run(main())
