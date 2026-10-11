# MiniKarts

Prototipo de karts hecho con Godot 4.5.1. Juega en horizontal desde el navegador del teléfono, sin instalar un APK.

## Jugar

[Abrir MiniKarts](https://largomaniamlg-lab.github.io/minikarts/)

Joystick izquierdo para dirigir; el kart acelera solo. Botones de freno, marcha atrás, salto y disparo a la derecha. El freno tiene prioridad y no activa la marcha atrás. Recuperar devuelve el kart al último checkpoint. Completa tres vueltas o pulsa Nueva carrera para empezar otra vez.

Pista de 18 metros de ancho, curvas variadas, seis obstáculos bajos y ocho cajas destructibles. Las cajas se destruyen con disparos; los obstáculos bajos se pueden saltar.

## Proyecto y actualizaciones

Las fuentes de referencia están en `godot/`. Importa `godot/project.godot` en Godot **4.5.1 estable**. El ZIP `MiniKarts_Android_0_2_0_Proyecto.zip` se conserva como archivo histórico de la versión 0.2.0; no es necesario extraerlo para desarrollar.

Desde la raíz del repositorio, ejecuta `bash scripts/test.sh` para importar recursos y ejecutar la suite funcional de controles táctiles. En Cloud selecciona automáticamente el motor 4.5.1 instalado. En otros entornos puedes indicar el ejecutable con `GODOT_BIN=/ruta/a/godot bash scripts/test.sh`. El script rechaza versiones distintas y conserva los códigos de error. Requiere Bash (en Windows, Git Bash o WSL).

Edita las fuentes dentro de `godot/` para que los cambios queden revisables en Git. La caché `.godot/` no se versiona. Las fuentes y las pruebas iniciales son equivalentes a las del ZIP; el archivo `.import` generado se regenera al importar. La web existente se conserva: editar las fuentes no actualiza automáticamente los archivos exportados de la raíz. La exportación web reproducible es una tarea pendiente.

La versión web exportada está en la raíz de este repositorio. GitHub Pages publica desde `main` y `/`. Las actualizaciones se hacen en este repositorio y se consultan desde el mismo enlace. Si tienes una partida abierta, vuelve a abrir el enlace para cargar una nueva versión.

## Detalles de la versión web

Godot WebGL 2, sin hilos. El motor oficial se sirve comprimido como `game.wasm.gz` y el cargador lo descomprime en el navegador. Requiere un navegador moderno con WebAssembly, WebGL 2 y DecompressionStream, por ejemplo Chrome reciente en Android. No necesita cabeceras COOP/COEP ni SharedArrayBuffer.

No se publican claves de firma ni credenciales. El motor y sus componentes tienen sus avisos de licencia en `GODOT_LICENSE.txt` y `GODOT_COPYRIGHT.txt`.
