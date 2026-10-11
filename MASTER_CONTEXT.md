# MiniKarts — contexto maestro

## Objetivo y forma de trabajo

Crear un juego original de karts 3D, divertido y optimizado para Android, con una versión web para probar actualizaciones. El usuario dirige la creatividad desde su Samsung; Codex realiza programación, configuración, diagnóstico y pruebas en Cloud, minimizando operaciones manuales en Windows.

- Repositorio: https://github.com/largomaniamlg-lab/minikarts
- Web publicada: https://largomaniamlg-lab.github.io/minikarts/
- Plataformas objetivo: Android nativo, Web y Windows para desarrollo.
- Plan: [ROADMAP.md](ROADMAP.md). Trabajo concreto: [BACKLOG.md](BACKLOG.md).

## Reglas para futuras sesiones

Inspeccionar los archivos reales y las instrucciones de agentes antes de actuar. Usar el checkout existente: las tareas Cloud están aisladas; no crear worktrees salvo petición expresa. Trabajar en tareas pequeñas, explicar cambios importantes, preservar funcionalidades y ejecutar pruebas tras cambios relevantes. Preferir soluciones sencillas compatibles con Godot; no reescribir sin necesidad. Comunicar en español qué cambió, qué se comprobó y qué queda pendiente.

Solicitar intervención únicamente para requisitos imprescindibles, decisiones creativas importantes, operaciones destructivas o publicaciones que necesiten autorización. No publicar cambios ni distribuir APK sin autorización. Usar cambios Git pequeños y revisables. No incorporar propiedad intelectual de otras franquicias sin permiso. Distinguir siempre ejecución real, lectura de código, antecedentes comunicados y pruebas pendientes. No presentar rendimiento móvil o carreras manuales como verificados sin evidencia.

## Auditoría verificada — 11 de octubre de 2026

Base inspeccionada: commit `4ffd2bc4aabc1a280c5bc026d6cbf455ff43ef52`. Repositorio limpio antes de la auditoría; esta tarea solo añade documentación.

El checkout `/workspace/minikarts` contiene la exportación web, licencias y `MiniKarts_Android_0_2_0_Proyecto.zip`. Las fuentes Godot están dentro del ZIP: tres escenas, ocho scripts de juego, una suite de pruebas, configuración de proyecto y presets de exportación. No hay CI ni flujo reproducible de exportación web en el repositorio. La copia de trabajo `/workspace/minikarts-dev/MiniKarts_Android` coincide con los archivos del ZIP; contiene además datos generados. Esa copia está fuera de Git: editarla no registra automáticamente cambios en el repositorio.

Motor requerido: Godot 4.5.1, renderizador GL Compatibility, viewport 1280×720, interpolación física. Motor verificado en Cloud: `/workspace/.minikarts-tools/Godot_v4.5.1-stable_linux.x86_64`, versión `4.5.1.stable.official.f62fdbde1`. El comando global `godot` apunta a 4.6.3: usar explícitamente el motor fijado.

### Capacidades del juego

- Kart CharacterBody3D, velocidad máxima configurada 22 m/s; aceleración automática solo en modo táctil, teclado W/flechas en escritorio.
- Joystick proporcional con zona muerta 0,15 y giro suavizado; botones de freno, salto, disparo, marcha atrás, recuperación y nueva carrera. Liberación de acciones al perder foco.
- Freno táctil tiene prioridad sobre aceleración y marcha atrás. S permite frenar y retroceder en escritorio.
- Un salto desde el suelo, gravedad y aterrizaje. **No existe doble salto**: el código impide saltar en el aire y la suite lo comprueba. La mención anterior de doble salto queda como antecedente no confirmado; implementar esa mecánica requiere decisión creativa.
- Circuito procedural de unos 18 m de ancho, radio variable, barreras, seis bloques y ocho cajas destructibles. Geometría primitiva y colores propios.
- Disparos cada 0,35 s, velocidad 55 m/s, vida 2 s; raycast entre posiciones para evitar atravesar paredes finas y exclusión del kart emisor.
- Cámara de seguimiento suavizada, raycast para evitar obstáculos y reposicionamiento al recuperar.
- Cuatro checkpoints ordenados, tres vueltas, cronómetro y mejor vuelta de la carrera; recuperación conserva el reloj. Reiniciar restaura 14 obstáculos y limpia proyectiles.
- HUD y mensaje de llegada; sin cuenta atrás, pantalla dedicada de resultados, rivales, progresión o audio de juego implementado. Los archivos audio worklet de la web son infraestructura del motor, no prueba de sonidos de juego.

### Pruebas ejecutadas en esta auditoría

Sobre una extracción temporal del ZIP, con XDG_CACHE_HOME, XDG_DATA_HOME y XDG_CONFIG_HOME dirigidos a carpetas temporales:

1. `--version`: Godot 4.5.1 confirmado.
2. `--headless --path <proyecto> --editor --import --quit`: importación correcta, sin errores.
3. `--headless --path <proyecto> --script tests/v02_test.gd -- --force-touch`: única suite disponible, 21 comprobaciones declaradas, `MiniKarts v0.2 test: 0 failures`, salida 0. Cubre aceleración/freno/reversa táctiles, salto único, multitáctil, destrucción, pared fina, reinicio, checkpoints, final y recuperación.
4. `--headless --path <proyecto> --quit-after 120`: escena principal ejecutada, salida 0.
5. Chromium mediante Playwright y servidor Python del checkout: pulsar Jugar, cargar motor y datos, retirar overlay de carga, canvas 1280×720, volver al menú. Sin excepciones JavaScript. Aparece un 404 de favicon.ico, cosmético.
6. Diagnóstico temporal de teclado: reverse durante 60 frames deja velocidad 0; accelerate durante 60 frames alcanza 10 m/s. Confirmada la discrepancia del HUD que anuncia B como reversa: kart.gd solo procesa esa acción en modo táctil. Espacio está asignado tanto a jump como handbrake.

No se recompiló la exportación web: se validó el artefacto existente. No se validó que game.pck sea reproducible a partir del ZIP. Las pruebas de vueltas mueven el kart a checkpoints programáticamente; no equivalen a jugar una carrera completa. Sin pruebas en Samsung físico, mediciones de FPS móvil, instalación Android, firma APK ni validación Windows nativa en esta auditoría.

### Problemas, riesgos y límites

- Fuentes dentro de ZIP y copia editable fuera de Git: riesgo de cambios perdidos y de divergencia entre fuente y exportación.
- B anunciado pero inoperante en escritorio; espacio activa salto y freno de mano. Suite actual solo fuerza modo táctil.
- Sensación de giro, cámara, colisiones y HUD en pantallas pequeñas pendientes de prueba real. Muchos nodos y barreras individuales pueden afectar rendimiento; no hay mediciones que lo demuestren todavía.
- Checkpoints por proximidad y cruce de meta; faltan pruebas de marcha atrás sobre meta, alta velocidad y límites. La cámara carece de pruebas específicas.
- Web requiere WebAssembly, WebGL 2 y DecompressionStream; motor gzip de unos 9,2 MB. No necesita hilos ni SharedArrayBuffer. La comprobación local no prueba el despliegue remoto actual.

## Android y Cloud

Preset Android: versión 0.2.0, código 5, paquete org.minikarts.prototype, ARM64 activado y x86_64 desactivado, sin Gradle, package/signed=false. Preset Windows x86_64 presente; preset Web ausente. No hay APK en el checkout. La firma e integridad del APK previo fueron comunicadas por el usuario, no verificadas aquí.

Java disponible en Cloud; adb, sdkmanager y apksigner no están en PATH; ANDROID_HOME, ANDROID_SDK_ROOT y JAVA_HOME no están establecidos. Directorios de plantillas inspeccionados vacíos. Exportación Android aún no reproducible en este entorno. El APK ARM64 previo no debe suponerse compatible con el emulador x86_64.

El usuario informa que publicó el entorno minikarts el 11 de octubre tras el onboarding. Esta sesión confirma que funcionan el motor instalado, la importación, la suite y Chromium; no confirma restauración en una máquina nueva. install_script y start_skill se guardaron en el onboarding anterior; esta auditoría no modifica configuración Cloud. El navegador integrado de ChatGPT funciona en Samsung según el usuario; el error de nuevas tareas en Chrome queda de baja prioridad.

## Próximo ciclo

Primero versionar fuentes y preparar comprobaciones reproducibles sin cambiar comportamiento. Después corregir controles de escritorio con regresiones y preparar exportación web; adelantar Android para pruebas móviles. Esta auditoría no implementa cambios de juego ni publica. Esperar instrucciones del usuario para implementar.

## Actualización — fuentes incorporadas al repositorio

El usuario autorizó MK-01 tras la auditoría. La fuente de referencia pasa a ser `godot/project.godot` y los scripts, escenas y pruebas bajo `godot/`. Se conserva el ZIP histórico y la exportación web existente sin cambios. Se excluyó de la extracción únicamente `icon.svg.import`, generado por Godot. La copia externa se comprobó contra el ZIP y se conserva, pero las nuevas ediciones deben hacerse dentro del checkout.

Ejecutar `bash scripts/test.sh` desde el repositorio (o mediante ruta absoluta desde otro directorio). Usa el Godot 4.5.1 instalado en Cloud; admite GODOT_BIN y rechaza otras versiones. Aísla datos/ajustes temporales, importa y ejecuta la suite original, preservando los códigos de salida. La caché del proyecto está ignorada. Las mecánicas no se han cambiado. MK-02 continúa pendiente.

## Actualización — controles y exportación web

B procesa reversa también en escritorio; Shift sustituye espacio para el freno de mano, que solo actúa con conducción activa. La suite táctil original se conserva; `desktop_test.gd` añade ocho comprobaciones de teclado, prioridades y salto sin frenado involuntario.

Preset Web sin hilos añadido. Plantillas oficiales 4.5.1 descargadas con verificación SHA-512; se instalan únicamente las Web. `install-web-templates.sh`, `export-web.sh`, `prepare-web.py` y `smoke-web.py` reproducen instalación, exportación y comprobación. Salida a directorio temporal, controles táctiles forzados, WASM gzip con mtime fijo y loader de descompresión existente. La web de la raíz y el ZIP histórico se conservan; estas mejoras aún no están publicadas. Android sigue pendiente.

Multijugador para cuatro personas: objetivo consultado por el usuario, sin implementación. Véase MK-13; no asumir aprobación de alojamiento ni de cambios creativos.

## Preparación de publicación web2

El usuario autorizó publicar la nueva web. Exportación generada desde las fuentes del commit 790ef37, copiada a la raíz con loader/PCK/WASM coherentes. Marcador visible 0.2 web2 y URL del iframe versionada. Cambios: controles corregidos y modo táctil forzado en Web. No incluye multijugador. El envío a GitHub y despliegue Pages se comprueban aparte; preparar archivos no acredita publicación.

## Corrección web3 — controles táctiles

El usuario detectó interfaz de escritorio en el móvil. Se corrigió args del loader a ["--", "--force-touch"]: Godot requiere separador para OS.get_cmdline_user_args(). El exportador conserva la corrección en futuras versiones. Prueba Chromium pasada y captura inspeccionada: joystick izquierdo y botones ATRÁS, FRENO, SALTO, DISPARO, RECUPERAR y NUEVA CARRERA visibles. La comprobación anterior de args y arranque no acreditaba visibilidad real de controles; ahora la captura permite revisarla. Sin cambios de física ni APK.

## Piloto de foto 2D y cuerpo 3D — prototipo local

El usuario autorizó un piloto con la cara de la foto compartida como imagen fija y cuerpo 3D. `assets/drivers/friend_face.png` contiene un recorte fotográfico preparado con asistencia de edición de imagen y fondo transparente; no es un escaneo facial ni una cabeza 3D. `scripts/driver.gd` crea cuerpo de geometría original, inclinado con dirección y velocidad vertical. Sprite3D billboard muestra siempre la expresión fija hacia la cámara. Las colisiones y físicas del kart no se cambian. La cabeza acompaña la posición del kart pero no tiene animación facial.

Primera versión a revisar visualmente. Las pruebas existentes pasan, pero no sustituyen evaluación física en Samsung. No publicar la foto ni esta versión del piloto hasta aprobación del usuario. La web anterior se conserva en la raíz; exportación del piloto solo local.

## Publicación autorizada del piloto — web4

El usuario aprobó publicar la versión con su foto. Exportación probada copiada a la raíz, con marcador 0.2 web4 · Piloto de foto. Incluye cuerpo 3D y cara 2D billboard; conserva controles táctiles. La autorización de publicación reemplaza la espera indicada en la entrada previa. APK y multijugador no incluidos.

## Corrección de caché de datos del piloto — web5

Captura Samsung mostraba controles táctiles pero kart sin piloto. El loader solicitaba game.pck sin versión, permitiendo reutilizar datos antiguos. Se añade al fetch del PCK un identificador derivado de SHA-256 del artefacto; futuras exportaciones regeneran ese identificador. Página marcada web5. No es necesario borrar los datos del navegador.

## Diagnóstico de publicación — web6

Web5 consta como desplegada con éxito en GitHub Actions (run 38104622317), pero el usuario continúa viendo el kart anterior. La causa en el móvil no está confirmada. Se publica una ruta nueva piloto-web6.html y un mainPack con nombre derivado del contenido: game-5f81e7e4c4333fc5.pck. Esto elimina reutilización del nombre anterior tanto para HTML como para PCK. El exportador genera paquetes con nombre por contenido para futuras versiones. Mantener enlaces antiguos compatibles.

## Ajuste solicitado de tamaño en pantalla

Cámara de seguimiento pasa de 7 m/4,3 m (distancia/altura) a 5,8 m/3,6 m en seguimiento y recuperación. Cara pasa de pixel_size 0,00065 a 0,00072 y centro 1,16 m para mantenerla sobre el cuerpo. Aumenta el tamaño aparente sin cambiar colisiones, velocidad ni giro. Exportación local para revisión; no publicada aún. Se corrige además la página de entrada de exportaciones temporales para que no apunte a un HTML de una versión histórica.

## Publicación autorizada — web7

El usuario autorizó publicar el ajuste de cámara y tamaño de cara. Exportación local verificada copiada a la raíz; acceso directo piloto-web7.html y mainPack game-1e5fd3e454290320.pck. Cámara 5,8 m/3,6 m, cara pixel_size 0,00072. Sin cambios de conducción. Se conservan los accesos antiguos; para este ajuste usar web7.

## Multijugador privado — primera implementación local

El usuario priorizó carreras con tres amigos y aprobó también disparos que provocan trompo/protección. `scripts/network.gd` es autoload; servidor Godot/WebSocket autoritativo, salas por código de seis caracteres, cuatro jugadores, estados lobby/countdown/racing/results, colores/nombres, tres vueltas y resultados. Clientes interpolan posiciones y envían controles; no deciden vueltas, impactos ni destrucciones. El tiro pasa a altura compatible con el chasis y raycast admite inicio dentro de colisión móvil. Trompo 1 s, velocidad ×0,25 y protección 3 s.

Véase MULTIPLAYER.md para comandos, contenedor, pruebas y limitaciones. Nuevas pruebas de reglas: 21 comprobaciones; se conserva la suite táctil y de teclado. No asumir que un servidor Cloud/local está accesible en Samsung. Alojamiento público WSS pendiente de selección, autorización del coste y acceso. La web publicada se conserva; no se ha publicado este prototipo ni contratado servicios.

Verificación: 50 comprobaciones Godot sin fallos, exportación y arranque web correctos, cuatro conexiones WebSocket contra servidor nativo y contenedor, y cuatro clientes Chromium crean/comparten sala y arrancan sincronizados desde la interfaz. No acredita carrera manual completa ni prueba de cuatro teléfonos. `render.yaml` prepara una opción gratuita de alojamiento sin desplegarla; falta una cuenta autorizada y comprobar las condiciones actuales del proveedor.

## Nuevos pilotos y elementos del grupo — preparación local

El usuario eligió alojamiento gratuito, pero pidió incorporar primero tres pilotos, un obstáculo neutral móvil, piernas decorativas y un proyectil basado en sus imágenes. Hay cuatro caras seleccionables con el botón Piloto 1/4: original, maquillaje, sonrisa y barba; las caras siguen fijas y los cuerpos 3D se animan. Son recortes procesados con el generador de imágenes a partir de las fotos, no copias idénticas píxel a píxel.

El recorte de la foto del amigo dormido fue rechazado por el filtro del generador (categoría sexual). Se informó al usuario y se preparó un dormilón ilustrado, vestido con pijama y almohada, como sustituto provisional: no afirmar que se haya incorporado la foto original. El usuario puede revisar ese diseño antes de publicarlo. Cruza la pista de lado a lado; el contacto provoca pérdida de velocidad, trompo y protección, decidido por el servidor en multijugador. Doce imágenes de piernas decoran el exterior sin colisiones; los pinos se conservan. El proyectil pasa a imagen de paquete blanco con lazo verde, con física y cadencia originales.

Las suites de Godot pasan 58 comprobaciones (21 táctiles, 8 escritorio, 29 multijugador), incluidos selección de piloto, posición compartida del neutral, contacto físico, movimiento y reinicio sin duplicar decoración. Cuatro conexiones reales conservan los cuatro pilotos elegidos. Exportación web local y arranque en Chromium correctos; evaluación física en Samsung, carrera manual completa y publicación siguen pendientes.

La prueba de cuatro clientes Chromium también pasó con un piloto diferente elegido desde el botón en cada navegador: salas, cuatro karts, selección compartida y salida sincronizada, sin errores JavaScript/GDScript. Captura de revisión en `/workspace/generated_images/minikarts-memes-preview.png`. Ningún cambio de este ciclo se ha publicado ni se ha creado alojamiento.

## Enlace de prueba solicitado — web8 del grupo

El usuario pidió un enlace para probar este ciclo. Se prepara una publicación de prueba separada: `prueba-grupo.html`, con iframe `grupo-web8.html` y paquete `game-de1644f0a9e13ecb.pck`. La portada habitual y web7 se conservan. Modo individual mediante argumento `--solo-preview`: oculta Amigos y deja elegir los cuatro pilotos, probar piernas, neutral ilustrado provisional y proyectiles. No contiene dirección localhost ni servidor público; la portada explica que las salas online están pendientes. El paquete y la página se verificaron en Chromium local con recursos 200, controles táctiles y retorno. El resultado del despliegue se registra después; preparar archivos no acredita publicación.

Publicación confirmada: commit eb3c3de enviado a main; Pages completó con Status Success en https://github.com/largomaniamlg-lab/minikarts/actions/runs/38107831914. Enlace de prueba: https://largomaniamlg-lab.github.io/minikarts/prueba-grupo.html?v=web8. El Cloud bloquea la petición directa al dominio Pages con CONNECT 403; no presentar el arranque remoto en Samsung como verificado. El arranque local del contenido publicado y el despliegue de Pages sí están comprobados.

## Selector visual y carrera offline contra IA — ciclo actual

El usuario pidió elegir claramente al piloto, proyectiles casi al doble de tamaño y modos online/offline con bots. El menú inicial muestra las cuatro caras y permite carrera contra tres rivales IA, entrenamiento a solas y acceso a la sala online cuando hay servidor configurado. Abrir el menú pausa los karts y el neutral; cambiar a entrenamiento elimina los rivales. Selección de cara compartida con el modo online. El proyectil mide visualmente 1,5 m frente a 0,8 m (1,875 veces); se conservan raycast, velocidad y cadencia.

`offline_race.gd` controla cuenta atrás, cuatro participantes, checkpoints ordenados, tres vueltas, posición, clasificación, recuperación y revancha. `bot_driver.gd` conduce con la misma física del jugador, sigue la pista, salta obstáculos, dispara a cajas/karts y se recupera desde su último checkpoint si se atasca. La IA es un primer prototipo; no representa dificultad equilibrada. En las pruebas el jugador también recibe un controlador automático exclusivamente para verificar una carrera física completa: no se ha jugado manualmente ni controlado el Samsung.

El usuario confirmó que no dispone de cuenta Render y necesita crearla desde el móvil. `render.yaml` y el contenedor ya preparan el alojamiento gratuito; no existe servicio público ni URL WSS. El menú sin URL desactiva online y lo explica. El cliente permite hasta 60 s para conectar; esto no garantiza superar todas las suspensiones del alojamiento gratuito. Hace falta crear/conectar la cuenta, desplegar, obtener URL y verificar cuatro teléfonos. No se solicitan contraseñas en chat.

Este ciclo permanece local y pendiente de autorización de publicación. El enlace web8 existente todavía no incluye este menú ni los bots. Las evidencias finales se registran en MULTIPLAYER.md después de concluir las comprobaciones.

Verificación final de este ciclo: 72 comprobaciones Godot sin fallos (21 táctiles, 8 escritorio, 29 reglas de sala y 14 de carrera offline). Los cuatro corredores completaron físicamente tres vueltas, con tiempos entre 53,88 y 62,57 s en una simulación automática; no es una medición del teléfono ni una partida manual. Revancha y cambio de personaje restauran progreso/caras; entrenamiento elimina los tres bots. Protocolo real de cuatro conexiones correcto. Cuatro Chromium seleccionan pilotos diferentes desde el nuevo menú y arrancan una sala sincronizada. Tras corregir el tamaño de retratos y el reinicio de etiquetas IA, la exportación final arranca carrera offline en Chromium sin errores. Capturas: `/tmp/minikarts-character-menu.png` y `/tmp/minikarts-offline-bots.png`. La exportación temporal usada para red local lleva ws://127.0.0.1:8080 y nunca debe publicarse: preparar otra sin URL para la prueba offline o con WSS real para online.

## Publicación autorizada — prueba web9

El usuario creó su cuenta Render y pidió el enlace para probar mientras se prepara el servidor. Autoriza actualizar la prueba separada con selector y tres bots. Se prepara `grupo-web9.html` con pack `game-dc4a8f5c207623ed.pck`, servidor vacío y `--solo-preview`: online desactivado, sin direcciones locales ni campo de configuración accesible desde Amigos. `prueba-grupo.html` apunta a esta versión; la portada habitual y web7/web8 se conservan. Las bibliotecas/recursos compartidos son idénticos por SHA-256 a los publicados.

Cuenta Render creada por el usuario, pero sin acceso de alojamiento concedido a Cloud ni credenciales Render vinculadas. El usuario debe conectar el repositorio desde Render y aplicar el blueprint gratuito; su creación por sí sola no despliega el servidor. No solicitar secretos por chat. Pendiente URL pública WSS y validación por Internet.

Publicación web9 completada: commit 391ae43 enviado a main; GitHub Pages finalizó con Status Success en https://github.com/largomaniamlg-lab/minikarts/actions/runs/38109128066. La exportación pública (sin localhost, sin servidor configurado) superó Chromium táctil, carrera con bots y Jugar/Volver. Enlace: https://largomaniamlg-lab.github.io/minikarts/prueba-grupo.html?v=web9. La descarga directa desde Cloud a github.io continúa bloqueada por el proxy (CONNECT 403); el éxito del despliegue no acredita todavía una partida en Samsung. Servidor Render sigue pendiente de conexión/despliegue desde la cuenta del titular y URL pública.

## Render: fallo por memoria y corrección de arranque

El servicio del usuario es `minikarts-multiplayer`, plan Free, URL https://minikarts-multiplayer.onrender.com. Su primer despliegue (1b12383) falló por superar 512 MiB durante el arranque. Reproducción local con las fuentes actuales en contenedor limitado a 512 MiB: el editor de Godot en `server.sh` fue terminado, exit 137, OOMKilled=true. Una importación posterior dentro del mismo límite también dispara OOM: no ejecutar el editor en el proceso alojado.

Corrección: `Dockerfile.multiplayer` importa recursos durante la construcción mediante `server.sh --import-only`, guarda la caché dentro de la imagen y arranca con `--preimported`. Ese modo valida que exista la caché y ejecuta directamente el juego/servidor; si falta, falla de forma explícita para reconstruir, en lugar de lanzar el editor y consumir memoria. El arranque local sin argumentos mantiene la importación habitual. Sin cambios de jugabilidad, plan de alojamiento ni exportaciones web.

Pruebas: construcción Docker correcta con TLS/SHA-512 activos; contenedor nuevo limitado a 512 MiB arranca y abre PORT=10000; protocolo real con cuatro clientes supera sala, permisos, cuenta atrás, movimiento, disparos y desconexión. Contenedor limpio adicional bajo el mismo límite ejecuta cuatro salas y dieciséis jugadores simultáneos hasta racing, OOMKilled=false; pico de memoria 106160128 bytes (101,24 MiB). Esta medida pertenece al contenedor local, no a Render. Pendiente volver a desplegar el último commit desde Manual Deploy → Deploy latest commit y comprobar Live antes de conectar/publicar el cliente online.

## Render Live y cliente online — web10

El usuario aportó captura de Render: despliegue bd3bc4f con estado `Deploy succeeded | Live`, duración 51 s. Evidencia del proveedor enviada desde su cuenta, no una verificación de red desde Cloud. Servicio público `https://minikarts-multiplayer.onrender.com`; cliente configurado con `wss://minikarts-multiplayer.onrender.com`.

Se prepara `grupo-web10.html` y se actualiza la prueba del grupo a web10 para habilitar Online; se conservan web9, portada habitual y los recursos/pack idénticos por SHA-256. Incluye selección, entrenamiento y carrera con tres bots. No se cambia la física. La prueba de cuatro clientes contra WSS público quedó bloqueada antes de contactar el servidor: `InvalidProxyStatus: HTTP 403` del proxy Cloud. No describirla como superada ni como fallo del servidor. La sala por Internet y cuatro móviles siguen pendientes de prueba del usuario; las pruebas locales de protocolo/contenedor ya pasaron.

## Motes solicitados y propuestas de ropa para Jordan

El usuario autorizó los motes Kikoso, Largo, Sipollo y Antocino (corrige el cuarto nombre), aplicados al selector y a los bots. Pidió tres ejemplos de la foto original de Jordan con la única modificación de añadir calzoncillos. La solicitud de edición para añadir bóxers opacos, conservando el resto de la foto, fue rechazada en entrada por la herramienta (moderation_blocked, categoría sexual). No se generó ninguna versión ni se sustituyó el dormilón; no repetir la misma solicitud para eludir ese bloqueo. Pendiente imagen de entrada admisible para las propuestas y elección del usuario. Motes preparados localmente, sin publicación en este ciclo.

## Jordan aprobado y ampliado — preparación web11

El usuario aportó una nueva entrada con la zona cubierta. La herramienta aceptó añadir bóxers azul oscuro; el usuario eligió el primer ejemplo y canceló las demás variantes. Se generó un recorte transparente del adulto vestido y su almohada a partir de ese ejemplo, conservando los originales generados. `godot/assets/memes/jordan.png` sustituye visualmente al dibujo provisional, cuyo archivo se conserva pero ya no se usa.

Tamaño ×1,875: sprite 7,5 m de ancho frente a 4 m, área de contacto 6,5625 × 2,15625 × 4,3125 m. Sprite y collider se elevan localmente para apoyar su base en la pista. La trayectoria y altura de referencia de red (0,75 m) se conservan, igual que oscilación, trompo, ralentización, protección y reinicio. Se incorporan también los motes Kikoso, Largo, Sipollo y Antocino, ya aprobados para selector y bots.

Verificación local: las suites existentes superan 72 comprobaciones con Jordan; los cuatro karts completan tres vueltas físicas contra bots. La suite de reglas ampliada supera 30 comprobaciones, incluida colisión a 2,6 m del centro que antes quedaba fuera del neutral; total 73 comprobaciones distintas. Se prepara `grupo-web11.html`, pack `game-92e835746874b27b.pck` y portada de prueba; sin publicación ni redeploy Render en este ciclo. Para activar online el contacto más grande, servidor y cliente deben actualizarse juntos: publicar fuentes/web y después Manual Deploy → Deploy latest commit en Render. El servidor actual aún tiene el neutral anterior.

El usuario autoriza ahora publicar todo este ciclo para probarlo. Web11 preparada para publicación en el enlace del grupo, manteniendo las versiones anteriores. La exportación local superó el arranque Chromium, HTTP 200 de recursos y Jugar/Volver. Pendiente verificación del despliegue Pages y actualización manual de Render desde la cuenta del usuario para sincronizar el área de contacto de Jordan.

Publicación autorizada web11 completada: fuentes 776cf25 y artefactos dc26f98 enviados a main. GitHub Pages completó correctamente el run https://github.com/largomaniamlg-lab/minikarts/actions/runs/38135064730. Enlace https://largomaniamlg-lab.github.io/minikarts/prueba-grupo.html?v=web11. Pendiente redeploy de Render para el nuevo contacto de Jordan; la web offline ya incluye Jordan ampliado y los motes.

El usuario pidió conectar Render a Codex Cloud para gestión autónoma. Verificado: RENDER_API_KEY ausente y borrador sin secretos existentes. Se guardó requisito de secreto RENDER_API_KEY con destino exclusivo api.render.com, y dominios personalizados api.render.com, minikarts-multiplayer.onrender.com y largomaniamlg-lab.github.io, preservando presets y scripts. Guardado confirmado, requires_publish=true. Falta valor seguro, guardar/publicar el entorno y validar acceso real a la API; no está conectado todavía. No pedir ni copiar claves en chat o repositorio. Una vez aplicada la configuración, consultar servicio y despliegues mediante API autorizada antes de operar, y confirmar que corresponden a minikarts-multiplayer del repositorio correcto. Esta preparación no despliega Render ni sustituye la autorización del titular en sus ajustes.

## Audio preparado — 11 de octubre de 2026

Música arcade original en bucle de 64 s; fanfarria de meta de Kenney Music Jingles, CC0 1.0, con licencia y procedencia conservadas en `godot/assets/audio/README.md`. Efectos originales sintetizados: motor con tono según velocidad, freno, salto, aterrizaje, disparo, impacto, cajas, trompo y cuenta atrás/salida. Mezclador SONIDO con música/efectos independientes y silencio global; preferencias `user://sound.cfg`, pausa al perder foco. Pool limitado a 12 efectos, atenuación de sonidos lejanos, sin inicialización en servidor/headless; física y protocolo sin cambios.

Validación: suite existente (73 comprobaciones, 0 fallos, sin errores de Godot), exportación 4.5.1 y Chromium táctil con gesto requerido. Medición de PCM WebAudio confirma música audible y cero señal con silencio; desactivar silencio recupera sonido; cuenta atrás, salida, motor aumentando de tono y disparo durante carrera con tres bots. iPhone/Safari y equilibrio de volúmenes en móvil físico pendientes. Fuentes y artefactos web12 preparados localmente; publicación pendiente de autorización específica.

Prueba adicional online local: dos clientes Chromium se unen a la misma sala, arrancan sincronizados y activan motor y señal de salida; sin errores del navegador. No es una prueba de escucha desde cuatro móviles reales.

Mezclador web: sliders de música y efectos comprobados de forma independiente; música a cero produce silencio y vuelve al subirla. Smoke de la landing web12 superado: recursos del juego HTTP 200, controles táctiles configurados y Volver funciona. Publicación pendiente; el enlace público mantiene web11 hasta autorizar el push.

## Conexión y salas — mejora preparada, 11/10/2026

Web12 fue publicada con autorización en el commit `3b96a94`; GitHub Pages completó el despliegue y se verificaron landing, loader y pack públicos HTTP 200. El usuario informa que sus amigos no conectan desde ese mismo enlace. La dirección WSS publicada es correcta y una prueba actual contra Render con cuatro clientes pasó; esto no identifica la causa en sus móviles. Prueba de Chromium contra HTTPS público bloqueada por `ERR_CERT_AUTHORITY_INVALID` del entorno, sin desactivar verificación TLS. Pendiente captura/móvil/navegador del fallo real.

Preparada web13: normalización de espacios, saltos de línea, espacios no separables y minúsculas en códigos tanto en cliente como servidor; validación de seis caracteres sin truncar un código pegado. Tres intentos automáticos de conexión (hasta 40 s cada uno, intervalo 3 s), contador visible y reintento manual sin salir de la pantalla. Salir cancela los intentos pendientes. Mensajes distintos para sala inexistente, llena o carrera comenzada; errores del servidor visibles durante seis segundos y texto ajustado al panel. No añade reconexión durante una carrera ni conserva salas al reiniciar el servidor.

Suite: 75 comprobaciones, 0 fallos; exportación Godot 4.5.1 correcta. Prueba táctil específica: código vacío explica formato, servidor apagado provoca tres intentos automáticos y permite Crear sala de nuevo tras arrancar el servidor. La publicación web13 y despliegue del servidor mejorado están pendientes de autorización; el enlace público sigue web12.

### Publicación web13 verificada

El usuario autorizó publicar web13 y actualizar servidor. Se enviaron `44ae9da` y `581d20d` a `main`. GitHub Pages run `38141223273` terminó con Success; landing pública sirve `grupo-web13.html` y `game-a006ab41d1cdd14b.pck` con HTTP 200. Render Free desplegó `581d20d`, deploy `dep-db5of9jbc2fs739ja4k0`, estado Live. Prueba pública real WebSocket superada con cuatro clientes independientes y códigos en minúsculas con espacios/saltos de línea: sala compartida, límite de capacidad, autoridad, Listo, cuenta atrás, movimiento, disparos solicitados y desconexión. Esto no confirma el funcionamiento en los móviles de los amigos; pendiente su nueva prueba.

Uso: Jugar → elegir piloto → ONLINE → nombre → Crear sala. Compartir los seis caracteres sin cerrar/recargar el juego. Amigos abren el mismo enlace, eligen piloto, ONLINE, nombre y código, Unirse. Esperar a que estén todos dentro, todos Listo y creador Iniciar carrera. No entrar a una carrera ya iniciada; no se necesita introducir servidor manualmente. Enlace: https://largomaniamlg-lab.github.io/minikarts/prueba-grupo.html?v=web13 .

## Navegador de salas — web14 preparada, 11/10/2026

Petición del usuario: ver salas disponibles y entrar tocando una, sin introducir código. Implementado listado en el servidor (`list` → `rooms`) con código interno, nombre del creador y ocupación; solo salas esperando con huecos. No son salas secretas: los visitantes de este servidor pueden encontrarlas. Las salas vacías desaparecen al salir el último jugador; llenas y carreras iniciadas no se ofrecen. Consultar la lista mantiene activa la conexión del visitante, respetando límites de mensajes y clientes existentes.

Cliente: entrar en ONLINE conecta y busca salas automáticamente; Actualizar salas y actualización cada tres segundos; botón Entrar · Sala de [nombre] · n/4. Crear sala une al creador automáticamente. Búsqueda y espera son pantallas distintas: Listo e Iniciar solo aparecen dentro. Se mantiene Tengo un código como alternativa. Solicitudes de entrada duplicadas se bloquean mientras llega respuesta y caducan tras diez segundos; reintentos de conexión y cancelación conservados. Pruebas del navegador usan diagnósticos de solo lectura para localizar controles sin depender de posiciones antiguas.

Verificado: 79 comprobaciones Godot sin fallos; exportación 4.5.1; protocolo real con cuatro clientes descubre salas por nombre/ocupación, entra desde el listado y oculta salas llenas; cuatro navegadores Chromium seleccionan sala sin teclear códigos, muestran cuatro karts y arrancan sincronizados. Sin prueba de teléfono físico ni identificación concluyente del fallo de conexión de la captura anterior.

Publicación pendiente de autorización. Orden obligatorio para no publicar una interfaz contra un servidor antiguo: enviar primero commit de fuentes (sin artefactos web14), desplegarlo en Render Free y verificar Live/listado; después enviar artefactos/landing web14 y comprobar Pages, pack y sala pública. Los clientes anteriores conservan Crear/Unirse por código. No activar autoDeploy ni cambiar el plan.

### Publicación verificada de web14 — 11 de octubre de 2026

Autorizada por el usuario y publicada: primero el servidor (commit `ef91b43`, despliegue Render `dep-db5osmdckfvc73auoiu0`, estado Live) y después la web (commit `83d8c4d`). La prueba WebSocket pública pasó con cuatro conexiones: listado, entrada por selección, capacidad, autoridad, listos, cuenta atrás, movimiento y desconexión. Se verificaron por HTTP el cargador web14, su paquete y el servidor configurado. El enlace estable `prueba-grupo.html`, incluido con `?v=web12` o `?v=web13`, sirve web14. Una partida ya abierta debe cerrarse y la página recargarse para cargar los cambios; GitHub Pages anuncia caché de hasta 600 segundos. Pendiente validación en teléfonos físicos.

### Fluidez online — mejora preparada, pendiente de publicación

Causa verificada en el código: el cliente desactiva la física local y dibuja el último estado del servidor (20 Hz), de modo que la conducción espera la red. Se añade presentación de movimiento (`network_motion.gd`): rivales interpolados con un búfer de 100 ms; anticipación visual local limitada a 150 ms, con dirección y freno actuales; correcciones mantienen posiciones, impactos, vueltas y resultados autoritativos. El servidor añade tiempo y velocidad a los estados y responde a ping para estimar el viaje de ida y vuelta. La cámara online sigue el ritmo de renderizado; el modo offline conserva su actualización física.

No es predicción completa con repetición de entradas y reconciliación física. Saltos, disparos y colisiones siguen esperando la autoridad del servidor; latencia alta, bloqueos de WebSocket y bajo rendimiento móvil requieren evaluación adicional. No se ha medido la latencia del teléfono del usuario.

Godot 4.5.1: 92 comprobaciones, cero fallos (79 existentes y 13 de movimiento). La prueba determinista con actualizaciones a 20 Hz y llegadas irregulares a 20 m/s mantiene pasos visuales máximos de 0,333 m a 60 Hz. Exportación web realizada correctamente. Prueba reproducible de cuatro navegadores con retraso variable: `python3 scripts/test-network-delay.py /tmp/minikarts-web.EXPORT`. No se publica sin autorización; actualizar primero servidor y después el enlace estable.

Durante la prueba visual se detectó agotamiento de la cola de paquetes al dibujar cuatro clientes por software. Corregido: recepción cliente limitada a 512 KiB/128 paquetes y emisión de estados de sala/resultado a 5 Hz (carrera y cuenta atrás siguen a 20 Hz). Estas colas siguen acotadas; no se desactiva la detección de errores en las pruebas. Web15 preparada en el enlace estable, publicación pendiente.

Validación final: cuatro clientes Chromium a 320×180 por software, con los mismos controles y aserciones que la prueba estándar a 640×360, crearon/seleccionaron sala y arrancaron la carrera con 60–120 ms de retraso añadido por sentido. Cero errores de cola o script. RTT observado por los clientes: 297–313 ms, incluyendo procesamiento del entorno; no es una medición del móvil del usuario. El identificador de ping es entero para evitar errores por redondeo JSON. Comando: `MINIKARTS_TEST_WIDTH=320 python3 scripts/test-network-delay.py /tmp/minikarts-web.r4k4fZ`. La prueba de protocolo también pasó con cuatro conexiones independientes. Paquete final: `game-1f2d97b369bceec5.pck`; cargador `grupo-web15.html`.
