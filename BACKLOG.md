# MiniKarts — backlog

Base: auditoría del 11 de octubre de 2026. MK-01, MK-02 y MK-03 completadas el 11 de octubre de 2026; las demás tareas siguen pendientes. No hay autorización para publicación.

## MK-01 — Versionar fuentes y reproducir las pruebas (completada, fase 1)

Fuentes incorporadas en `godot/`, equivalentes al ZIP salvo el archivo generado icon.svg.import. ZIP y web conservados; cachés excluidas. `bash scripts/test.sh` fija Godot 4.5.1 y ejecuta importación y suite. Las instrucciones Cloud se adaptan al nuevo directorio. La copia externa se conserva sin sobrescribirla.

Aceptación: escenas, scripts, configuración y pruebas visibles en Git; contenido inicial equivalente al ZIP; importación y suite con 0 fallos desde una copia limpia; ningún cambio de mecánicas; documentar qué fuentes son la referencia y cómo preservar modificaciones de la copia externa.

## MK-02 — Alinear controles de escritorio y HUD (completada, fases 1–2)

Resolver B anunciado como marcha atrás pero ignorado en escritorio y la asignación compartida de espacio a salto/freno de mano. Preservar prioridad del freno y controles táctiles; acordar el mapeo final si cambia la experiencia.

Aceptación: B/HUD coherentes, pruebas de teclado para avance, frenado, reversa y salto; espacio no produce frenado involuntario; suite táctil sigue pasando. No incorporar doble salto sin decisión creativa.

## MK-03 — Exportación web reproducible (completada localmente, fase 1)

Instalar plantillas oficiales verificadas 4.5.1, añadir preset Web sin hilos y documentar exportación, compresión y actualización conjunta de loader/PCK/WASM. Mantener inicialmente los artefactos actuales.

Aceptación: desde fuentes versionadas se genera exportación en directorio temporal; Chromium carga motor y datos, desaparece overlay, canvas válido y sin excepciones; botones Jugar/Volver funcionan; gzip y tamaños del loader coherentes; no publicar automáticamente. Añadir prueba automatizada útil de arranque.

## MK-04 — Preparar APK reproducible (P1, fase 8 adelantada)

Configurar SDK/JDK/plantillas compatibles en Cloud y generar variantes ARM64 y x86_64 en salida local. No inventar claves ni sustituir la firma previa sin analizar continuidad de actualización.

Aceptación: compilación repetible, arquitecturas y manifiesto verificados; instalar/arrancar en destino compatible cuando esté disponible; verificación de firma del artefacto; documentar claramente cuándo solo se compiló. Mantener 0.2.0/código 5 como antecedente, asignar nuevos números cuando se prepare una nueva versión. Sin distribución ni publicación sin autorización.

## MK-05 — Evaluación en Samsung y carrera completa (P1, fases 2–3)

Preparar protocolo breve para que el director pruebe desde su teléfono; medir carga/FPS y recoger sensibilidad, cámara, legibilidad y comodidad de pulsaciones simultáneas. La intervención física del usuario es necesaria si Cloud no tiene acceso al teléfono.

Aceptación: dispositivo/navegador o APK y versión registrados; tres vueltas completas, recuperación, llegada y reinicio comprobados; freno+giro+disparo simultáneos; cambios de foco/orientación y áreas seguras revisados; mediciones y observaciones guardadas antes de ajustar sensaciones.

## MK-06 — Regresiones de checkpoints y recuperación (P2, fase 3)

Aceptación: casos de meta en reversa, cruce rápido, checkpoints fuera de orden, caída, recuperación junto a meta y reinicios repetidos; sin vueltas inválidas, objetos residuales ni variaciones del número de obstáculos.

## MK-07 — Cámara y colisiones (P2, fase 2)

Aceptación: comprobar cámara cerca de barreras/cajas, salto, recuperación y reversa; registrar penetraciones o saltos bruscos; pruebas reproducibles de casos detectados. Optimizar únicamente a partir de evidencia.

## MK-08 — Diseño del salto (P2, fase 2; decisión creativa)

El código actual solo permite un salto y prueba que no haya otro en el aire. Acordar conservarlo o implementar doble salto, con alturas, límites y efecto visual original.

Aceptación: decisión registrada; pruebas acordes que cubran suelo, aire, aterrizaje y recuperación; actualizar documentación sin eliminar silenciosamente la mecánica aprobada.

## MK-09 — Salida y resultados (P2, fase 3)

Aceptación: cuenta atrás impide salida prematura; reloj arranca al comenzar; pantalla de resultados muestra tiempo total y mejor vuelta; reinicio devuelve estado inicial y conserva reglas de checkpoints.

## MK-10 — Rendimiento y HUD móvil (P2, fases 2–4)

Aceptación: presupuesto de FPS acordado con mediciones en Samsung; UI accesible en tamaños y áreas seguras objetivo; evaluar nodos/materiales/barreras con profiler antes de reducirlos; sin pérdida de controles simultáneos.

## MK-11 — Automatización (P2, fases 1 y 8)

Aceptación: CI fija Godot, verifica importación y suite real, conserva códigos de salida y publica resultados de prueba; compilaciones como artefactos privados/revisables según autorización, sin despliegue automático no autorizado.

## MK-12 — Arte, audio, IA y progresión (P3, fases 4–7)

Dividir en tareas pequeñas tras aprobar dirección creativa y estabilidad. Aceptación: recursos originales/licenciados, coste móvil medido; IA completa vueltas y se recupera; selección y progreso tienen persistencia comprobada. No mezclar estas ampliaciones con correcciones básicas.

## MK-13 — Carreras privadas para cuatro amigos (implementación local; publicación pendiente)

El usuario aprobó carreras privadas con tres amigos e impactos con trompo. Implementación local: sala por código, cuatro karts y servidor Godot autoritativo mediante WebSocket. La publicación y las pruebas desde teléfonos siguen pendientes.

Aceptación pendiente por Internet: cuatro clientes completan una carrera de tres vueltas con posiciones y resultados coherentes; código de sala y plazas funcionan; desconexión no bloquea la carrera. Medir latencia y suspensión del navegador en teléfonos. Cajas y disparos ya se sincronizan; reconexión a la misma identidad queda para otra tarea. No se ha contratado ni desplegado ningún servicio público.

Estado MK-13: implementación y reglas locales preparadas; cuenta atrás, posiciones autoritativas, nombres/colores, checkpoints/vueltas, clasificación, host transferible, impactos y protección. Pruebas y detalles en MULTIPLAYER.md. Falta alojamiento público, revisión de coste/acceso, prueba con cuatro teléfonos y ajuste de latencia. No considerar completada la experiencia por Internet.
