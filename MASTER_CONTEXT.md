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
