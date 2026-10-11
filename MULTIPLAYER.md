# Carreras privadas para cuatro

Prototipo de servidor autoritativo Godot 4.5.1 y clientes WebSocket para Web y Godot nativo. La web publicada anterior sigue intacta: este trabajo no despliega ni contrata un servidor público.

## Flujo de juego

Antes de abrir Amigos, tocar Piloto 1/4 para recorrer las cuatro caras disponibles. Abrir Amigos, escribir nombre, crear sala o introducir código para unirse. Máximo cuatro pilotos por sala. Todos marcan Listo; el creador inicia una cuenta atrás de tres segundos. Se conserva aceleración automática, joystick, freno, reversa, salto, disparo y recuperación. Cada jugador tiene un kart de color diferente; los rivales muestran nombres y la cara elegida. La elección queda fija durante la sala.

Se completan tres vueltas con checkpoints ordenados. Clasificación por tiempo de llegada; los restantes tienen un minuto después del primer finisher para terminar. Límite global de carrera: diez minutos. El creador puede volver a la sala desde resultados. Si se desconecta, otro jugador pasa a ser creador. No hay reconexión a la misma identidad en esta versión; se puede salir y entrar en una sala nueva.

Impacto: pierde el 75 % de velocidad, trompo de un segundo y tres segundos de protección total, incluido el trompo. Los tiros se consumen al impactar incluso si el receptor está protegido. Cajas, disparos, impactos, vueltas y posiciones se deciden en el servidor. Recuperar no cancela trompo ni protección.

El dormilón neutral oscila lateralmente por la pista y aplica el mismo trompo/protección al tocar un kart. El servidor comparte su posición y decide sus impactos por sala; las piernas decorativas no tienen colisiones. Los proyectiles usan la nueva imagen sin cambiar alcance, cadencia ni raycast.

## Ejecutar y probar en Cloud

```bash
bash scripts/test.sh
PORT=8080 bash scripts/server.sh
```

El servidor queda en primer plano; abrir otra sesión para las comprobaciones:

```bash
python3 scripts/test-multiplayer.py ws://127.0.0.1:8080
MULTIPLAYER_SERVER_URL=ws://127.0.0.1:8080 bash scripts/export-web.sh
python3 scripts/smoke-web.py /tmp/minikarts-web.DIRECTORIO
python3 scripts/test-multiplayer-browser.py /tmp/minikarts-web.DIRECTORIO
```

Usar el directorio que imprime la exportación. Python WebSockets y Playwright/Chromium están disponibles en este Cloud. Las pruebas de reglas fuerzan posiciones desde el servidor para comprobar tres vueltas; no acreditan una carrera manual completa. El test de protocolo usa cuatro conexiones reales, y el de navegador usa clientes Web reales con la interfaz de sala. `?test=1` habilita únicamente datos de diagnóstico de la sala que ese cliente ya recibe; no concede control adicional.

## Contenedor de despliegue

```bash
docker build -f Dockerfile.multiplayer -t minikarts-multiplayer .
docker run --rm -p 8080:8080 minikarts-multiplayer
```

Esperar el mensaje `MiniKarts WebSocket server listening on 8080` antes de conectar: el inicio importa los recursos. PORT es configurable. El contenedor usa usuario sin privilegios y verifica SHA-512 oficial del motor. En Cloud la construcción necesita los proxies existentes, resolución de su hostname y el bundle CA confiable del entorno como secreto BuildKit `build_ca`; no desactivar TLS ni verificación de artefactos. Es configuración de construcción de este entorno, no credenciales de juego.

## Publicación pendiente

GitHub Pages solo aloja los clientes estáticos. Hace falta un servicio con proceso persistente, WebSocket y TLS (URL wss://). Un proxy inverso debe preservar Upgrade/Connection y permitir conexiones largas. Mantener una sola instancia en este prototipo: las salas están en memoria y no se comparten entre réplicas. Reiniciar el servidor termina las salas.

Tras elegir alojamiento y revisar coste/acceso, desplegar el contenedor. Después exportar con `MULTIPLAYER_SERVER_URL=wss://DOMINIO-REAL` para que los amigos no tengan que introducir la dirección. No usar localhost en una publicación. El código de sala es para invitaciones informales, no autenticación fuerte. Límites iniciales: cuatro salas, dieciséis conexiones y sesenta mensajes por segundo por cliente; validación de inputs finitos y rango 0–1, corte de mensajes mayores de 4 KiB. Inputs ausentes durante 1,5 s frenan el kart.

`render.yaml` deja preparada una opción de prueba con el plan `free` de Render y despliegues automáticos desactivados. Es un borrador, no un servicio creado: revisar disponibilidad, límites y suspensión del plan antes de aplicarlo desde una cuenta autorizada. La URL real solo se obtiene al desplegar. La suspensión o reinicio del servicio elimina las salas; no prometer continuidad con un alojamiento gratuito.

Antes de llamar listo al multijugador por Internet: probar cuatro teléfonos, latencia real, suspensión del navegador, desconexiones y una carrera completa. La primera versión interpola snapshots a 20 Hz y no tiene predicción local; la conducción puede sentirse retrasada con conexiones lejanas. Debe evaluarse desde Samsung antes de ampliarlo.

## Verificación de esta implementación

El 11 de octubre de 2026, Godot 4.5.1 pasó las 21 comprobaciones táctiles, las 8 de escritorio y las 21 de reglas multijugador, sin errores. Se exportó la web y arrancó en Chromium, con recursos HTTP 200 y retorno a la portada correcto. El protocolo pasó con cuatro conexiones WebSocket contra el servidor nativo y contra el contenedor construido con el código actual. Esas comprobaciones incluyen capacidad de sala, permisos de inicio, cuenta atrás, rechazo de posiciones/vueltas enviadas por clientes y cambio de creador tras desconexión.

Cuatro clientes Chromium con entrada táctil habilitada crearon y compartieron la sala usando su interfaz, introdujeron nombres/código, mostraron los cuatro karts, marcaron Listo y arrancaron la carrera sincronizada sin errores de JavaScript o GDScript. Capturas locales: `/tmp/minikarts-four-player-lobby.png` y `/tmp/minikarts-four-player-race.png`. La prueba usa un viewport reducido para limitar el coste de renderizado por software del Cloud; no mide FPS ni latencia de un móvil. Tras revisar la captura se añadió un fondo oscuro al panel de sala para separar su texto del HUD del circuito.

Las pruebas automatizadas de vueltas usan posiciones controladas desde el servidor. No se ha jugado una carrera completa manualmente ni validado el rendimiento en cuatro teléfonos. El contenedor, las pruebas y las exportaciones temporales se prepararon localmente; esta implementación no se ha enviado a GitHub ni publicado en Pages.

## Alta en Render desde Samsung

1. Abrir https://dashboard.render.com/ y crear cuenta, preferiblemente entrando con GitHub.
2. Cuando el código esté autorizado y publicado, crear un Blueprint desde `largomaniamlg-lab/minikarts`, permitiendo a Render leer ese repositorio. Se incluye `render.yaml`: servicio Docker, plan `free`, una instancia, PORT=10000, despliegue automático desactivado. Revisar que la interfaz mantiene el plan gratuito y sus condiciones antes de aplicar; no elegir un plan de pago.
3. Esperar a que el servicio arranque; copiar solo su URL pública (no claves ni contraseñas). Su equivalente WebSocket es `wss://DOMINIO-ASIGNADO`.
4. Exportar el cliente con `MULTIPLAYER_SERVER_URL` establecido a esa URL y probarlo antes de publicar. El Samsung no debería introducir direcciones técnicas: solo nombre/código y botones de sala.

La cuenta no se ha creado ni conectado desde Cloud; no hay credenciales de alojamiento disponibles. Solo el usuario puede completar el inicio de sesión y conceder el acceso de su cuenta. El servicio gratuito puede suspenderse: comprobar sus límites actuales. Los 60 s de espera del cliente son un margen inicial, no una garantía de arranque en frío.

## Pruebas del modo offline

`bash scripts/test.sh` incluye `tests/offline_race_test.gd`, usando paso físico fijo 1/60 s. Se simulan realmente los cuatro karts y el controlador automático del jugador existe solo en la prueba: no se teletransportan al siguiente checkpoint para acreditar las vueltas. `python3 scripts/test-offline-browser.py DIRECTORIO_EXPORTADO` verifica el menú visual y arranque contra tres bots en Chromium con entrada táctil. Revisar también la captura: la ausencia de errores por sí sola no acredita legibilidad de los retratos.

Resultado del ciclo selector/IA, 11-10-2026: 72 comprobaciones Godot, 0 fallos; cuatro clientes de protocolo y cuatro clientes Chromium superan conexión/sala/selección/salida sincronizada. La carrera offline física completa se supera para los cuatro karts (3 vueltas cada uno), seguida de revancha, actualización de caras y eliminación de bots en entrenamiento. La exportación final corregida supera el test táctil de selector/carrera offline; retratos revisados en captura. No se ha desplegado Render, publicado este ciclo, jugado manualmente ni probado cuatro teléfonos. La exportación temporal de prueba usa un servidor de loopback: no distribuirla ni publicarla; generar otra sin URL para offline o con el WSS público cuando exista.

### Enlace de despliegue preparado

Con la cuenta Render creada, abrir https://render.com/deploy?repo=https://github.com/largomaniamlg-lab/minikarts e iniciar sesión. Autorizar acceso al repositorio si Render lo pide; revisar que el blueprint ofrece `minikarts-multiplayer` con plan gratuito, y desplegarlo. Si el enlace no abre el asistente, usar Dashboard → New → Blueprint → repositorio. La cuenta del usuario no está conectada a Cloud: este paso de autorización debe realizarlo el titular. Después compartir únicamente la URL pública del servicio; no secretos.

La prueba web9 se publica como offline (URL de servidor vacía), conservando los accesos anteriores. No sirve para carreras por Internet hasta que se prepare otra exportación con el WSS real.

## Evitar OOM en Render Free

El primer despliegue superó los 512 MiB al ejecutar `--editor --import` durante el arranque. Se reprodujo con un contenedor limitado a `--memory=512m --memory-swap=512m` (exit 137). La importación pasa a la construcción de la imagen (`RUN bash scripts/server.sh --import-only`); su CMD usa `--preimported`, valida la caché y no inicia el editor. La construcción necesita más memoria que el servidor: no confundir el proceso de build con la instancia Free.

La imagen corregida arranca con PORT=10000 y pasa el test de protocolo de cuatro clientes dentro del límite. Prueba adicional: cuatro salas y dieciséis jugadores alcanzan racing sin OOM, pico local 101,24 MiB. No garantiza todavía el despliegue real: en el servicio Render existente abrir Manual Deploy → Deploy latest commit. El plan y autoDeploy=false se conservan. Esperar Live; después validar WSS y actualizar la web online. El enlace offline web9 continúa funcionando sin cambios.

## Servidor activo y cliente web10

El titular confirmó mediante captura `Deploy succeeded | Live` para bd3bc4f. Endpoint del cliente: `wss://minikarts-multiplayer.onrender.com`. Web10 habilita el modo online sin direcciones técnicas para los jugadores; web9 sigue disponible como prueba offline. Para jugar: elegir piloto, Online, escribir nombre, Crear sala o Unirse con código, todos Listo, creador Iniciar carrera.

La prueba automatizada desde Cloud al servidor público está bloqueada por el proxy (HTTP 403, antes del handshake con Render). No acredita ni rechaza el funcionamiento del servidor. Validar en Samsung dos clientes primero y luego los cuatro amigos, incluyendo conducción, disparos y carrera completa. El despertar de Free puede tardar 50 s o más, según el aviso real del panel; los 60 s del cliente no garantizan todos los arranques en frío.

## Actualización coordinada de Jordan (web11 pendiente de publicación)

El nuevo recorte de Jordan se muestra a ×1,875 y el área autoritativa de contacto aumenta en la misma proporción. Posición compartida y protocolo no cambian. Hasta actualizar Render, el servidor mantiene el tamaño de contacto anterior; no dar por verificado Jordan grande en partidas públicas. Publicar fuente y cliente autorizados, luego Manual Deploy → Deploy latest commit y esperar Live. Motes del selector/bots incluidos en el mismo ciclo.

## Listado de salas (web14 preparada)

ONLINE abre un navegador de salas por nombre del creador y número de jugadores. Crear sala entra automáticamente; los demás tocan Entrar en esa sala. El servidor responde a `list` con `rooms` (code, host, players, capacity). Solo ofrece salas esperando y con huecos, y la UI consulta cada tres segundos. El código sigue como alternativa. Todos los visitantes del mismo servidor pueden descubrir estas salas; no se anuncian como secretas. La publicación debe desplegar el servidor con soporte de listado antes de publicar los artefactos web14.
