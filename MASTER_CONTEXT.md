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

### Web16 preparada — personajes y salas de diez (sin publicar)

Nombres en orden: Kikoso, Largo, Sipollo, Antocino, Fubux, Orehas, Young Ex, Super Mar-IA, Ketamine Yamal. Catálogo compartido entre selección, bots y servidor. Selección en tres páginas con cuerpos ilustrados/fotográficos; solo la cara visible en carrera. Los retratos nuevos son derivados de las fotos mediante edición generativa: no se garantiza identidad de píxeles con los originales. Kikoso conserva su retrato de cara: falta volver a adjuntar su primera foto completa para recuperar el cuerpo original.

Salas de diez, diez colores, parrilla de dos columnas por cinco filas y servidor limitado a 48 conexiones. Velocidad máxima 65 km/h; anticipación visual ajustada al mismo límite. Se conserva la mejora de fluidez de web15. Nueve personajes pueden repetirse entre diez jugadores.

Validación local: 115 comprobaciones Godot, cero fallos; protocolo con diez conexiones, rechazo del undécimo, elección de nueve identidades y carrera; Chromium muestra las tres páginas y otro ensayo con un navegador más nueve conexiones muestra los diez coches y arranca la carrera sin errores. Exportación y prueba de arranque web superadas. No se ha probado con diez teléfonos físicos ni esta versión en Render Free. No se publica todavía por instrucción del usuario; servidor y web públicos siguen en web14. Paquete preparado: game-9bba19d3ffe01419.pck; cargador grupo-web16.html.

### Personajes y distancias completados — preparación web17

Trece personajes: Kikoso, Largo, Sipollo, Antocino, Fubux, Orehas, Young Ex, Super Mar-IA, Ketamine Yamal, Tushkroisant, Yisus Samuel, Noga y Enriquesido. Kikoso ya usa su cuerpo de la foto reenviada. Retratos derivados mediante edición generativa, caras en carrera y cuerpos en cuatro páginas de selección.

Carreras online de hasta 13 pilotos, parrilla curva con dos carriles y colores diferentes. Opciones 3/6/9 vueltas antes de crear sala; autoridad del creador, valor incluido en lista/estados y compartido con todos. Valores JSON decimales enteros aceptados; entradas no válidas vuelven a tres. Contra IA: 3/6/12 rivales y las mismas distancias. Entrenamiento también respeta vueltas. Velocidad 65 km/h y mejora visual de red conservadas.

Validación: 382 comprobaciones nativas sin fallos, protocolo real de 13 clientes con nueve vueltas y rechazo del decimocuarto, Chromium con un navegador y doce clientes de protocolo muestra 13 coches en carrera de seis vueltas; arranque web correcto. No equivale a trece teléfonos físicos. El usuario solicita terminar las tareas pendientes; se procederá a actualizar backend primero y después el enlace estable.

### Backend actualizado — web17

Render Live: despliegue `dep-db5qd3142hec739rvgv0`, commit `00b86d8`. Selección real de nueve vueltas y doce bots por el menú de Chromium superada, además de las pruebas anteriores. Web17 preparada con paquete `game-59c7e5a74e58634c.pck`; tanto la portada principal como el enlace estable de grupo apuntan a la versión nueva. Pendiente publicar este cliente y verificar GitHub Pages.

### Publicación verificada de web17 — 11 de octubre de 2026

Backend Live `dep-db5qd3142hec739rvgv0` (commit `00b86d8`); cliente publicado en `1b9d5d1`. La prueba WebSocket pública pasó con trece clientes: distancia de nueve vueltas, directorio, selección, capacidad, autoridad, salida, movimiento y migración del creador. GitHub Pages devuelve 200 para el cargador y el paquete `game-59c7e5a74e58634c.pck`; el enlace estable, incluso con `?v=web12` y `?v=web13`, apunta a web17. Portada principal actualizada también.

Pruebas Chromium locales de selección (cuatro páginas), nueve vueltas/doce bots, modo por defecto de tres bots, arranque y trece coches online superadas. 382 comprobaciones nativas sin fallos. El intento adicional de navegación directa desde Chromium a la web pública se detuvo por `ERR_CERT_AUTHORITY_INVALID` del proxy de este entorno; no se desactivó TLS. Los recursos públicos y el WebSocket sí se verificaron con clientes que confían en la CA del entorno. No se ha validado esta versión con trece teléfonos físicos ni Safari/iPhone real.

No quedan personajes pendientes de foto. Pruebas con amigos, medición de fluidez en teléfonos y futuras mejoras de reconexión siguen como validación/desarrollo posterior, no como cambios bloqueados de esta entrega. Para cargar la versión nueva, cerrar la partida abierta y recargar el enlace habitual; una pestaña ya abierta conserva su versión y puede intervenir la caché del navegador.

### Web18 — fluidez en Render Free

Respuesta visual local en cada fotograma, anticipación acotada a 5 m/250 ms y congelación ante estados obsoletos; corrección contra el servidor y reinicio inmediato ante golpes. Rivales con margen adaptativo según variación de llegadas y reloj de presentación monotónico. No es reconciliación física completa; colisiones, saltos, vueltas y resultados mantienen autoridad del servidor.

Estados serializados una vez por sala, precisión de un centímetro en posiciones de red, envío regular a 20 Hz durante carrera y descarte de estados nuevos cuando la cola de un cliente supera 8 KiB. Las entradas se envían solo durante cuenta atrás/carrera, hasta 30 Hz al cambiar y 20 Hz como latido. Comparación de escenario de trece pilotos: mediana de 3428,5 frente a 4794 bytes por estado (aprox. 28 % menos por mensaje; no mide ahorro total por segundo).

428 comprobaciones nativas superadas en conjunto. Pruebas de selección, nueve vueltas/doce bots, arranque y navegador con doce compañeros de protocolo superadas. Cuatro Chromium a 640×360 con retrasos añadidos de 60–120 ms por sentido pasan sin errores; RTT observado 278–308 ms incluye procesamiento del entorno. Sin pruebas con teléfonos físicos. Exportación game-6a052662d3a739bc.pck. Actualizar backend primero, cliente después.

Backend web18 Live: despliegue dep-db5r5b942hec739u8g20, commit 3a944a2. Cliente preparado con enlace estable sin cambios de URL.

Prueba WebSocket pública web18 superada con trece clientes: listado, selección, capacidad, autoridad, listos, cuenta atrás, movimiento, solicitudes de disparo y migración del creador.

### Publicación verificada de web18

Cliente a35c550 publicado tras backend Live. HTTP público confirma que index y el enlace estable con parámetros antiguos web12/web13 cargan grupo-web18.html; cargador y paquete de 15.501.480 bytes responden 200 y apuntan al servidor Render correcto. No se ha hecho una navegación Chromium pública por la limitación de certificados ya documentada. Se ha validado Chromium local y WebSocket/HTTP públicos. Servidor local de pruebas detenido.

### Web19 — controles multitáctiles

Joystick horizontal independiente de desplazamiento vertical, zona muerta 8 % y curva 1,4 para ajuste fino cerca del centro manteniendo giro máximo. No libera/repite la misma dirección en cada arrastre. Captura explícita por índice de dedo para cada botón, con persistencia al deslizar fuera y conteo de contactos compartidos: levantar uno no libera la acción sostenida por otro. Área de captura ampliada 6 unidades por borde, sin solapamiento entre acciones. Cancelación, pérdida de foco y reajuste de pantalla limpian entradas. Diagnóstico táctil solo con ?test=1.

Suite nativa completa sin fallos, con ocho comprobaciones nuevas de combinaciones, precisión, liberación, cancelación y reajuste. Chromium recibe cinco contactos reales por CDP y verifica joystick/freno/salto/disparo, arrastre vertical, propiedad del botón, dos dedos en disparo y touchCancel. El primer ensayo del navegador tenía mal definida la liberación CDP (envió contactos retenidos); corregido el controlador, prueba final superada sin relajar aserciones. Arranque web también superado. No equivale a prueba en iPhone/Android físicos. Paquete game-a69f3b392b97a22b.pck. Backend sin modificaciones: sigue web18 Live, compatible.

Web19 publicada en b1f5c29: enlaces estables con web12/web13 y portada cargan grupo-web19; cargador y paquete 15.507.736 bytes responden 200. Verificación HTTP pública superada.

### Web20 — Ruso, Dego y mAIk; dieciséis pilotos

Tres personajes añadidos en el orden de las fotos, cuerpos humorísticos derivados mediante edición generativa y caras independientes para carrera. Catálogo total y salas de 16, colores adicionales y parrilla curva de ocho filas/dos carriles. IA de 3/6/15 rivales. Se conservan 65 km/h, 3/6/9 vueltas y controles/red web18/web19. Nuevo jugador ocupa primer hueco libre; salir de la sala ya no permite que la siguiente incorporación se superponga con otro coche. Orden de parrilla actual: orden de incorporación con huecos reutilizados; repeticiones mantienen plaza. Sorteo/parrilla inversa/clasificación son propuestas, no implementadas.

Pruebas nativas completas superadas; reglas finales 341 comprobaciones sin fallos ni errores de script, prueba de hueco libre incluida. Chromium selecciona las cuatro páginas y mAIk, nueve vueltas/15 bots. Un Chromium con quince conexiones de protocolo muestra 16 karts y arranca carrera sin errores. Transparencia y retratos de cuarta página revisados visualmente. Backend primero, cliente después; sin prueba con 16 móviles físicos.

Backend web20 Live: commit 7712221, deploy dep-db5rs52d0e5s738gdv7g. Prueba pública de 16 conexiones superada: capacidad, directorio, selección de 16 identidades, nueve vueltas, autoridad, carrera, movimiento y migración del creador.

Web20 cliente publicado en 4c7ca8e. HTTP público confirma web20 desde portada y enlaces antiguos web12/web13; cargador y paquete 17.146.088 bytes responden 200. Servidor local de pruebas detenido. Sin pruebas con 16 teléfonos físicos.

### Web21 — controles en círculo y presentación renovada

Distribución elegida: izquierda solo joystick; derecha abajo ATRÁS, FRENO, SALTO y DISPARO más grande encima. Botones circulares con iconos vectoriales independientes de fuentes; captura circular tolerante y propiedad por dedo web19 conservadas. Utilidades a la derecha arriba, marcador compacto centrado y botón del cargador Volver a la derecha para no taparlo. Se conservan 16 personajes, Jordan, piernas, proyectiles, obstáculos, 65 km/h y vueltas 3/6/9.

Carrocería ovalada con morro, franja, asiento, llantas y escapes; sombra de contacto mediante un plano transparente, sin mapas de sombra de luz. Árboles redondeados, colinas, nubes, arco de meta y cielo degradado; nuevas decoraciones sin colisión. Cartel orientado a cámara para que no se lea invertido desde atrás. Circuito, caja de colisión del kart y autoridad física sin cambios. Es una adaptación procedural del estilo de la imagen, no reproduce su nivel de detalle.

Suite nativa completa sin fallos; cinco comprobaciones adicionales de distribución y captura circular pasan en ejecución focalizada. Chromium pasa selección/15 bots, contactos táctiles de cinco dedos, un navegador más quince conexiones muestra 16 coches en carrera sin errores. La exportación final pasa arranque, assets y retorno; captura real preview-web21.png inspeccionada. No hay pruebas en teléfonos físicos. Backend sigue web20 Live: cambios de presentación e interfaz no requieren desplegar otro servidor; protocolo y colisiones compatibles. Paquete final game-62fc3b21f4167b6b.pck, 17.164.184 bytes.

Web21 publicada en 422ccd4. HTTP público confirma portada y enlaces antiguos web12/web13; cargador y paquete de 17.164.184 bytes responden 200. SHA-256 del paquete descargado coincide con la exportación local probada. Servidor local de pruebas detenido.

### Web22 — nueva distribución pedida

Fila inferior derecha: ATRÁS, SALTO y DISPARO, alineados por centro. FRENO encima. Salto/disparo 132 unidades, atrás/freno 112 (aprox. 18 % mayores), con zonas táctiles circulares separadas. Se conserva joystick y propiedad multitáctil. Prueba nativa focalizada de conducción/controles sin fallos, con aserciones del nuevo orden, separación y tamaños. Chromium recibe cinco contactos simultáneos y verifica acciones independientes, arrastre vertical, doble contacto en disparo, liberación y cancelación sin errores. Paquete game-b5c6d85c80fb0e24.pck, 17.164.200 bytes. Cambios solo de controles; servidor sin cambios.

Web22 publicada en 86284b8. HTTP confirma que portada y enlaces antiguos web12/web13 cargan grupo-web22.html; cargador y paquete responden 200 con tamaño correcto.

### Web23 — marcador y menú durante la carrera

Información táctil en una única franja superior: vueltas, puesto offline, reloj y velocidad. Avisos temporales debajo, sin tapar el centro de la pista. Las opciones Recuperar, Nueva carrera, Salas online, Piloto y vueltas y Sonido se agrupan en Menú; se ocultan los antiguos botones sueltos, también al recuperar el foco. Abrir Menú libera contactos sostenidos. Se conserva la distribución inferior ATRÁS, SALTO, DISPARO, con FRENO arriba. Recuperar no reactiva un corredor offline que ha terminado. La carrocería ovalada vuelve a asignarse al campo de visual usado por las actualizaciones online, evitando acceso a un material nulo.

Suite nativa completa superada; prueba focalizada posterior verifica fila compacta, utilidades ocultas después de recuperar foco y liberación del joystick al abrir Menú. Chromium prueba HUD real y recuperación en 640×360, 1280×591 y 844×390, sin errores; capturas revisadas. Cinco contactos reales simultáneos conservan independencia, doble contacto y cancelación. Un navegador con quince conexiones WebSocket muestra los dieciséis coches en carrera y el marcador compacto. No equivale a pruebas en móviles físicos. Backend permanece web20, compatible. Paquete game-42f1963ad475553b.pck, 17.176.248 bytes.

Ajuste final Web23: abrir Menú cierra el panel de sonido para que no cubra la opción Piloto y vueltas. Prueba real de navegador recorre Sonido → Menú → Piloto y vueltas. Paquete final game-a9fedda31e8465f4.pck, 17176408 bytes.

Web23 final publicada en 5724e47. HTTP confirma portada y enlaces antiguos web12/web13 hacia el cargador final a9fedda31e8465f4. Cargador y paquete responden 200; paquete público de 17.176.408 bytes con SHA-256 idéntico al probado localmente. Servidor local de pruebas detenido.

### Web24 — giro más cerrado y suavidad de presentación

Dirección compartida por física autoritativa y predicción: radio a pleno giro 15 m frente a 22 m (+46,7 % de velocidad angular); subida de dirección 6/s frente a 3/s, liberación 12/s. Se conservan 65 km/h, controles y reglas. Predicción integra horizontes en pasos de 1/60 s para no aplicar el ángulo final a todo un paquete atrasado. Transformaciones actualizadas por red desactivan la interpolación física adicional (kart local/remotos, Jordan y proyectiles); el filtrado de red conserva sus límites y autoridad.

Cámara actualizada por fotograma: sigue la transformación interpolada offline y la posición de presentación online, sin interpolar de nuevo la cámara. Excluye coches del rayo de oclusión para que un rival no la empuje; mantiene las barreras estáticas. Las cámaras del servidor no ejecutan seguimiento ni rayos, reduciendo trabajo innecesario por jugador.

Suite nativa completa sin fallos; prueba focalizada nueva de conducción/cámara, nueve comprobaciones: trayectoria física y predicción coinciden durante 200 ms, giro más cerrado, cambio de dirección y liberación, velocidad limitada, rival sin salto de cámara y barrera respetada. Movimiento: 57 comprobaciones, incluyendo curvas bajo ráfagas de 60–220 ms: máximo 0,337 m y 0,021 rad por fotograma simulado a 60 Hz. Protocolo de 16 conexiones y cuatro navegadores reales a través de retrasos inyectados de 60–120 ms por sentido pasan (RTT observado 221–351 ms). Chromium con quince conexiones independientes muestra 16 karts, HUD y ausencia de segunda interpolación física; cinco contactos táctiles reales conservan independencia y cancelación. No son pruebas en móviles físicos ni garantizan eliminar problemas de conexión externos.

Backend Web24 Live: commit 9e9cc76, deploy dep-db6c8rd9fdbs73fkno0g, mismo servicio gratuito. Prueba pública de dieciséis conexiones pasa directorio, sala llena, autoridad, listos, arranque, movimiento, límites y migración de creador. Cliente final game-d1077de0082f9b98.pck, 17.180.504 bytes; arranque, assets y retorno por la portada Web24 superados en Chromium. Servidor local de pruebas detenido. Todos deben cerrar la sesión antigua y recargar para usar la misma dirección en cliente y servidor.

Web24 cliente publicado en aaaacc7. HTTP confirma portada y enlaces antiguos web12/web13/web23 hacia grupo-web24.html con token d1077de0082f9b98; cargador y paquete responden 200. SHA-256 del paquete público de 17.180.504 bytes coincide con la exportación probada localmente. Árbol de trabajo limpio tras guardar la verificación.

### Web25 — cuatro circuitos, rampas, clasificación y torneo

Circuitos nuevos de 900, 960, 1.050 y 1.150 m, con rectas y esquinas redondeadas. El primero se alargó desde la propuesta de 850 m para cumplir el mínimo de 50 segundos. Vueltas limpias de un bot, sin cajas/Jordan ni ataques: 51,82 / 57,58 / 61,27 / 66,23 s a física de 60 Hz. Son mediciones de simulación, no garantías con tráfico o dispositivos físicos. Rampas 2/3/4/5, un hueco por circuito; resto de rampas opcionales en media calzada. Hueco real de unos 9 m sin colisión de suelo, rampa de 1,6 m y lanzamiento automático. Impulso completo a partir del 98 % de 65 km/h, margen para cuantización; despacio, impulso insuficiente. Disparos reducen velocidad y pueden provocar caída. Respawn antes de la rampa conserva vueltas y reloj, con breve protección. Césped exterior decorativo sin suelo físico: salir de las barreras también recupera al piloto.

Cajas separadas entre sí, de obstáculos originales y de aproximaciones/aterrizajes de rampas. Cartel de meta reducido, plano y fijado al arco, sin billboard atravesando el travesaño. Selección de circuito y carrera suelta/torneo antes de comenzar. Mantiene 3/6/9 vueltas y 16 pilotos. IA sigue los nuevos trazados mediante persecución de ruta, modera curvas y acelera para el hueco; dispara cuando tiene objetivo. Gates de progreso cacheados y ordenados impiden saltarse el recorrido.

Torneo offline y online: clasificación de tres vueltas en el original, parrilla de carrera 1 por mejor vuelta individual (no tiempo total). Carreras 1–4 en los nuevos circuitos; vueltas elegidas aplican solo a carreras. Parrillas posteriores por resultado anterior. Puntos de 16 a 1 para terminados, DNF 0; desempate de campeonato por victorias, mejor clasificación y orden de incorporación. Empates de tiempo en una misma actualización también usan incorporación. Roster online cerrado al iniciar; creador continúa entre etapas con Listo y cuenta atrás. Reiniciar torneo borra puntos explícitamente. Identidades IA persisten entre etapas; podio actualiza el personaje del jugador si cambia offline. Podio 3D usa cuerpos existentes, brazo levantado/copa real y medallas numeradas 2/3. Resultados largos tienen scroll y no tapan continuar. Tabla de puntos solo se transmite en lobby/resultados, no en cada snapshot de carrera.

Pruebas: suite nativa original completa sin fallos; circuitos 96 comprobaciones de longitudes, rampas separadas, suelo ausente, salto rápido, caída lenta y tras disparo, respawn y vueltas completas. Torneo servidor 61 comprobaciones cubren las cinco etapas, parrillas, autoridad, puntuación única, DNF y nuevo torneo. Offline siete comprobaciones de progreso, identidades y reinicio. Chromium elige los cuatro circuitos y comienza clasificación; torneo completo sobre WebSockets reales mediante fixture local que acelera gates (no tiempos de vueltas reales), termina con podio sin errores. Un navegador más quince peers corre Gran Final con 16 coches; contactos táctiles reales de cinco dedos mantienen propiedad/cancelación. Podio inspeccionado con render GL nativo y web. El primer controlador de dropdown usaba teclado que enfocaba la primera fila; corregido a selección por ratón. Los peers auxiliares del test necesitaban leer/bufferizar estados continuamente para no bloquear pongs; corregido max_queue=None. No hay endpoints de trampas en producción: fixture solo se inicia explícitamente desde tests. Servidor sigue gratuito, sin modificar plan ni protocolo de autoridad.

Backend Web25 Live: commit 2278ea7, deploy dep-db6dt05ckfvc73d47o10, servicio gratuito existente. Prueba pública con dieciséis conexiones en Gran Final pasa capacidad, autoridad, nueve vueltas, movimiento, disparos y migración de creador. Paquete final game-aca2eaf1139991d8.pck, 17.288.520 bytes. El paquete final pasa arranque/assets/retorno desde portada y torneo completo en navegador con fixture local sobre WebSockets; gráficos de podio inspeccionados. Servidores locales de prueba y Xvfb detenidos. Todos deben recargar Web25 antes de crear sala para usar selección de circuito/torneo.

Web25 cliente publicado en 48cfc20. HTTP confirma portada y enlaces antiguos web12/web13/web24 hacia grupo-web25.html con token aca2eaf1139991d8; cargador y paquete responden 200. SHA-256 del paquete público de 17.288.520 bytes coincide con la exportación probada. Fuente/backend y cliente verificados; enlace estable conservado.

### Web26 — menú por pasos y garaje/sala

Combina las propuestas 2 y 3. Primer paso: carrera individual o torneo, independientes de IA/amigos. Segundo: garaje con cuerpo existente del piloto, cuatro tarjetas por página, circuito y 3/6/9 vueltas; IA muestra selector de rivales y torneo fija circuito de clasificación. Tercero: resumen y entrada a carrera IA o directorio de salas. Volver conserva opciones; reapertura sincroniza vueltas/rivales, resultados permiten regresar a configuración y se conserva continuación/podio del torneo. Menús centrados en formatos panorámicos, paneles claros redondeados, botones principales amarillos, textos sin glifos no disponibles. Retratos limitados a tarjetas; selección y carreras conservan las caras/cuerpos existentes. Inicialización tolera que la dirección del servidor aún no exista.

Sala online con piloto destacado, cada amigo en una fila, scroll para dieciséis participantes/resultados, texto más legible y HUD oculto mientras está abierta. Listo, inicio y compartir separados. Nombre inicial usa mote del piloto si aún era Piloto; nombres personalizados se conservan. Compartir abre diálogo del navegador o copia/enlace manual como alternativa; enlace estable incluye room y portada lo pasa al cargador, dejando el código de invitación preparado. Se mantienen directorio y código opcional. Sin cambios a protocolo, física, rampas ni backend: servidor Web25 compatible, mismo Render gratuito.

Validación: suite nativa de juego completa sin fallos tras corregir acceso temprano a dirección; nueva suite de menú 59 comprobaciones de cuatro combinaciones, navegación, ajustes, dieciséis retratos contenidos y regreso desde resultados. Chromium selecciona cuatro circuitos y torneo, cuatro páginas de pilotos y nueve vueltas/15 IA. Torneo completo por WebSockets locales con fixture explícita de gates termina en podio. Un navegador y quince peers entran por directorio y corren Gran Final; contactos reales de cinco dedos conservan independencia/cancelación. Exportación final pasa arranque, assets y retorno por portada; menú final probado en 640×360, 844×390 y 1280×591, creación de sala y enlace de compartir (diálogo nativo interceptado localmente, sin enviar mensajes). Capturas reales inspeccionadas. No son pruebas en teléfonos físicos. Paquete final game-0bd7144939779308.pck, 17.310.328 bytes; portada Web26 conserva enlace estable y enlaces antiguos.

Web26 publicada en 2763601. HTTP público confirma portada, índice y enlaces antiguos web12/web13 hacia grupo-web26.html. Cargador y paquete responden 200; SHA-256 público del paquete de 17.310.328 bytes coincide con la exportación final probada. Servidor local de pruebas detenido. Backend sigue Web25 Live; basta recargar el enlace estable para el nuevo menú.

### Web27 — escenarios temáticos y boost temporal

Velocidad: laboratorio/central nuclear, torres de refrigeración, depósitos, edificios, conductos, estanque verde y señales de radiación. Curvas: jungla tropical con palmeras/matorrales; Horquillas: desierto y talleres/cactus/rocas; Gran Final: ciudad futurista con edificios y luces. Juguete conserva su aspecto original. Cajas por tema: barriles cilíndricos de laboratorio con colisión acorde, cajas tropicales, combustible y energía; rampas/barreras adoptan paleta. Humores, Jordan y caras se conservan. Decoración estática sin colisión, comprobada respecto a todos los tramos cercanos; elementos repetidos en MultiMesh. Servidor omite la decoración de escenario para ahorrar recursos. Cielo y suelo cambian con circuito y vuelven al original al clasificar.

Boost autoritativo: un panel seguro en Velocidad, Horquillas y Gran Final; Curvas no tiene una recta libre de rampas con 100 m de margen. Panel de 14 m, chevrons y señales 80 km/h. Acelera gradualmente de 65 a 80 durante 3 s, desacelera al terminar; 6 s de cooldown y un uso hasta salir del panel, sin acumulación. Solo corredores activos avanzando por suelo. Disparo cancela boost; respawn/reinicio limpia estado. Rampas/approach de huecos y cajas se separan del panel. IA respeta límite temporal. Snapshot añade temporizador boost, predicción consume tiempo y replica cambios de límite, cliente no decide activación/duración. HUD indica BOOST.

Audio: usuario eligió exactamente https://teknoaxe.com/Link_Code_3.php?q=1702&genre=Drum_and_Bass para Velocidad. Todavía no se ha descargado ni verificado: dominio bloqueado por proxy 403. Borrador de entorno guardado añade teknoaxe.com y www.teknoaxe.com manteniendo los tres dominios anteriores; requiere revisar/guardar/publicar en ajustes. Runtime sigue revisión 12 sin esos dominios. Cambio de canción por circuito preparado si existe velocity_music.ogg; mantiene música original mientras falta archivo. No se ha sustituido por otra pista. Importador exige licencia CC BY 4.0 en ficha exacta, un único enlace MP3, HTTPS verificado, valida duración y genera Ogg normalizado más hashes/créditos. Desbloquear música y validar esa ficha sigue pendiente.

Validación previa a publicar: suite nativa completa sin errores, 130 comprobaciones nuevas de escenarios/boost y 6 de servidor (cliente no inventa/extiende boost, snapshot refleja disparo, no decoración en servidor). Vueltas limpias IA aproximadamente 51,13 / 57,57 / 60,60 / 65,55 s con boost, sin respawns; todos cumplen 50–80 s. Chromium prueba cuatro circuitos, torneo completo con fixture explícita de gates y podio, dieciséis conexiones por directorio y carrera, cinco contactos táctiles, audio PCM/mixer/silencio/disparo y arranque/assets/retorno. No son teléfonos físicos. Vistas generales renderizadas con fixture: exportación temporal independiente que incluye tests; la exportación de producción conserva exclusión tests/*. El primer intento de esa fixture tenía firma _process incorrecta y luego no estaba en pack (correctamente excluida); ambos problemas corregidos solo en el flujo de pruebas. Producción no incluye endpoints/fixtures de trampas.

Backend Web27 Live: commit 5150fc6, deploy dep-db6gh3ivcj2c73ari70g, mismo servicio gratuito. Comprobación focalizada adicional de HUD a nueve vueltas/16 corredores: 132 comprobaciones de boost/escenarios sin fallos. El panel mantiene ancho compacto y muestra BOOST. Vueltas limpias Gran Final: 65,57 s (corrección de redondeo anterior). Última exportación de producción pasa audio PCM/mixer y arranque/assets/retorno. Canción 1702 sigue pendiente por acceso del entorno.

Web27 cliente publicado en 0e9dc12. HTTP público confirma enlace antiguo web12 y cargador grupo-web27.html, ambos 200 con token d13d255889a6e173. Paquete público de 17.369.576 bytes tiene SHA-256 igual al exportado y probado. Servidor real pasa prueba de dieciséis conexiones en Velocidad, autoridad, tres vueltas, movimiento/disparos y migración de creador. Servidor local de pruebas detenido. Todos deben cerrar la partida antigua y recargar antes de crear una sala con boost. Pendiente únicamente canción 1702: guardado borrador de dominios, todavía sin aplicar/publish del entorno; mantener esa tarea en futuras sesiones.

### Web28 — recuperación de bots, boost y escenarios (música aplazada)

El usuario aplaza expresamente la música. No reabrir la configuración de dominios ni pedir la canción en este trabajo.

Correcciones: el mezclador se oculta al cambiar de fase y al abrir resultados offline; los respawns tienen 1,5 s sin colisión con otros karts para evitar empujones bajo la carretera. Al terminar, los karts siguen visibles pero dejan de bloquear a otros pilotos. Respawn de rampa a 30 m antes (antes 12); límite de repetición de lanzamiento 1,2 s. Bots detectan falta de desplazamiento real, vuelo excesivo (>2,5 s / altura >8 m) y se recuperan con protección breve. IA del circuito original pasa a 55–62 km/h y las nuevas rutas frenan menos en curvas; mantienen 65 km/h normal y 80 con boost.

Boost 5 s (antes 3), cooldown 6 s; siete paneles: Velocidad 3, Curvas 1, Horquillas 2, Gran Final 1. Se activan en tramos rectos separados de rampas, se puede frenar normalmente mientras dura el efecto. Obstáculos temáticos 18 por circuito nuevo (antes 12), decoración principal 24 sitios (antes 12), nubes y horizonte con montañas/dunas; ciudad con luna y estrellas. Cielo procedural con transición más suave. Decoración sin colisión y excluida en servidor; nubes/estrellas en un MultiMesh.

Pruebas: nueva bot_endurance_test.gd con 16 bots reales, countdown de 3 s, armas, tráfico, obstáculos y rampas. Cada bot debe acabar una vuelta en cada circuito en <=240 s; el ensayo detectó y permitió corregir caídas en bucle por respawns superpuestos. La medición base de circuitos desactiva solo boosts para conservar la referencia de 65 km/h: 51,73 / 56,83 / 60,75 / 65,83 s. El boost y la predicción física se comprueban aparte. Integración de torneo abre realmente el mezclador durante cada carrera y comprueba que no sigue visible sobre resultados/podio. Fixture local da 3 s antes de avanzar puertas para permitir entrada real del navegador; está excluida de producción.

Validación final Web28: scripts/test.sh completo termina con código 0, incluidos los 16 bots en los cuatro circuitos con salida normal. Reglas online 341, predicción 57, offline 64, handling 9, torneo 61, circuitos 120, torneo offline 7, menú 60, boost/escenarios 174 y servidor boost 6, todos sin fallos. Chromium pasa torneo real con mixer abierto en las cinco fases y podio despejado; arranque/assets/retorno de la exportación final también pasa. Prueba táctil de cinco contactos y PCM/mixer pasan. Los cuatro escenarios se seleccionan y renderizan sin errores. Paquete de producción: game-d8b831914a66783c.pck, 17.378.824 bytes, SHA-256 d8b831914a66783c20bdb25e1e21adcef44660e552aa2372cb4d0c1b3a50da22.

Backend Web28 Live: fuente 3eeeaa7714dccb73ef95bb072078a821b87f90ce; deploy dep-db6h90jrjlhs73eovad0; mismo servicio Render gratuito, sin cambio de plan. Cliente preparado: grupo-web28.html?v=d8b831914a66783c; index.html y prueba-grupo.html conservan URL estable y redirigen a este cargador.

Servidor público Web28 pasa prueba real con 16 conexiones en Velocidad: listado/entrada, capacidad, autoridad, listos, cuenta atrás, movimiento, disparos y desconexión. El ensayo reconoce ahora los 18 obstáculos de los circuitos nuevos. Cliente Web28 publicado conserva todos los cargadores anteriores para compatibilidad de caché; los jugadores deben cerrar una partida antigua y recargar antes de crear otra sala.
