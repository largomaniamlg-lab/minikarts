"""Helpers for the Godot lobby's read-only browser test diagnostics."""
def tap_control(page, key):
    page.wait_for_function('(key) => window.minikartsLobbyTest && window.minikartsLobbyTest.buttons[key]', arg=key, timeout=30000)
    rect = page.evaluate('(key) => window.minikartsLobbyTest.buttons[key]', key)
    bounds = page.locator('#canvas').bounding_box()
    page.touchscreen.tap(bounds['x'] + (rect['x'] + rect['width']/2) * bounds['width']/1280,
                        bounds['y'] + (rect['y'] + rect['height']/2) * bounds['height']/720)

def wait_connected(page):
    page.wait_for_function('window.minikartsLobbyTest && window.minikartsLobbyTest.connected && !window.minikartsConnectionTest.connecting',timeout=60000)
