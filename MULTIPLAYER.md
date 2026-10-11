# Carreras privadas para cuatro

Prototipo de servidor autoritativo Godot 4.5.1 y clientes WebSocket para Web y Godot nativo. La web publicada anterior sigue intacta: este trabajo no despliega ni contrata un servidor público.

## Flujo de juego

Abrir Amigos, escribir nombre, crear sala o introducir código para unirse. Máximo cuatro pilotos por sala. Todos marcan Listo; el creador inicia una cuenta atrás de tres segundos. Se conserva aceleración automática, joystick, freno, reversa, salto, disparo y recuperación. Cada jugador tiene un kart de color diferente; los rivales muestran nombres. La primera versión usa la misma cara de foto para todos.

Se completan tres vueltas con checkpoints ordenados. Clasificación por tiempo de llegada; los restantes tienen un minuto después del primer finisher para terminar. Límite global de carrera: diez minutos. El creador puede volver a la sala desde resultados. Si se desconecta, otro jugador pasa a ser creador. No hay reconexión a la misma identidad en esta versión; se puede salir y entrar en una sala nueva.

Impacto: pierde el 75 % de velocidad, trompo de un segundo y tres segundos de protección total, incluido el trompo. Los tiros se consumen al impactar incluso si el receptor está protegido. Cajas, disparos, impactos, vueltas y posiciones se deciden en el servidor. Recuperar no cancela trompo ni protección.

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
