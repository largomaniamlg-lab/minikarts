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

## Exportar y comprobar la web en Cloud

1. `bash scripts/install-web-templates.sh`: instala solo plantillas Web sin hilos, verificando SHA-512 oficial (la descarga completa es de unos 1,3 GB y se reutiliza).
2. `bash scripts/export-web.sh`: exporta desde `godot/` a un directorio temporal nuevo, indicado al terminar. No sobrescribe la web publicada. Usa Godot 4.5.1; admite GODOT_BIN y rutas XDG.
3. `python3 scripts/smoke-web.py /tmp/minikarts-web.XXXXXX`: comprueba el directorio obtenido con Chromium y Python Playwright disponibles en Cloud.

El exportador genera loader, PCK y WASM juntos, comprime WASM con gzip y reutiliza el cargador de descompresión existente. Activa controles táctiles y aceleración automática en la web, incluida la prueba desde escritorio. La publicación requiere autorización aparte.

Teclado en el proyecto nativo: W/flechas aceleran, A/D giran, S frena y permite reversa desde parado, B activa marcha atrás, espacio salta y Shift aplica freno de mano. El freno mantiene prioridad.

## Multijugador privado (prototipo local)

Salas para hasta trece pilotos, salida compartida, elección de 3, 6 o 9 vueltas, clasificación y trompos por disparos. Servidor requerido: `PORT=8080 bash scripts/server.sh`. Instrucciones, pruebas y publicación pendiente en [MULTIPLAYER.md](MULTIPLAYER.md). La versión pública existente sigue siendo individual hasta desplegar servidor y cliente.

### Selector y carreras offline (ciclo local)

Al arrancar se abre un menú con las cuatro caras. Pulsar una y elegir **Carrera · 3 rivales IA** para correr tres vueltas contra bots, o **Entrenar a solas**. **Menú · piloto** permite pausar y volver a elegir. La carrera contra bots tiene cuenta atrás, clasificación y revancha. **Online · con amigos** solo se habilita si la exportación incluye una URL de servidor; el alojamiento público está pendiente de alta en Render desde el móvil.

Validación offline adicional: `bash scripts/test.sh` y `python3 scripts/test-offline-browser.py DIRECTORIO_EXPORTADO`. Las pruebas físicas usan conducción automática, no una partida manual en un teléfono. Estas mejoras permanecen locales; el enlace de prueba web8 publicado todavía conserva la versión anterior.

Actualización web9: el usuario autorizó publicar estas mejoras en `prueba-grupo.html`; el juego habitual se conserva. Esta prueba incluye selección visual y carrera contra tres bots; online sigue pendiente del despliegue Render y la URL WSS.

Web10 conecta la prueba del grupo al servidor Render con WSS público y habilita Online. El usuario confirmó Live mediante captura; las partidas públicas quedan pendientes de validación en móvil porque el proxy Cloud bloquea la conexión al dominio con HTTP 403. La carrera offline con tres bots se conserva.
