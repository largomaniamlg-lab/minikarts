# MiniKarts

Prototipo de karts hecho con Godot 4.5.1. Juega en horizontal desde el navegador del teléfono, sin instalar un APK.

## Jugar

[Abrir MiniKarts](https://largomaniamlg-lab.github.io/minikarts/)

Joystick izquierdo para dirigir; el kart acelera solo. Botones de freno, marcha atrás, salto y disparo a la derecha. El freno tiene prioridad y no activa la marcha atrás. Recuperar devuelve el kart al último checkpoint. Completa tres vueltas o pulsa Nueva carrera para empezar otra vez.

Pista de 18 metros de ancho, curvas variadas, seis obstáculos bajos y ocho cajas destructibles. Las cajas se destruyen con disparos; los obstáculos bajos se pueden saltar.

## Proyecto y actualizaciones

El ZIP `MiniKarts_Android_0_2_0_Proyecto.zip` contiene las escenas y scripts GDScript editables. Para abrirlo, extrae el ZIP e importa su `project.godot` en Godot 4.5.1.

La versión web exportada está en la raíz de este repositorio. GitHub Pages publica desde `main` y `/`. Las actualizaciones se hacen en este repositorio y se consultan desde el mismo enlace. Si tienes una partida abierta, vuelve a abrir el enlace para cargar una nueva versión.

## Detalles de la versión web

Godot WebGL 2, sin hilos. El motor oficial se sirve comprimido como `game.wasm.gz` y el cargador lo descomprime en el navegador. Requiere un navegador moderno con WebAssembly, WebGL 2 y DecompressionStream, por ejemplo Chrome reciente en Android. No necesita cabeceras COOP/COEP ni SharedArrayBuffer.

No se publican claves de firma ni credenciales. El motor y sus componentes tienen sus avisos de licencia en `GODOT_LICENSE.txt` y `GODOT_COPYRIGHT.txt`.
