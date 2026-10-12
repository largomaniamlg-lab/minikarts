# MiniKarts — proyecto de calidad visual

Fecha: 12 de octubre de 2026. Estado: plan preparado; producción de recursos todavía no iniciada. Responsable creativo: usuario. Coordinación: agente principal.

## Resultado que buscamos

Un juego de carreras semirrealista, con vehículos y escenarios detallados, materiales creíbles, iluminación coherente y menús del mismo nivel. Las imágenes aportadas son objetivos visuales de referencia; la entrega debe demostrarse ejecutando el juego. No se promete igualar un título comercial concreto ni reproducir píxel a píxel una imagen generada.

Conservar 16 pilotos y sus motes, caras y cuerpos; Jordan y las bromas; cinco circuitos; conducción base 65 km/h y boost 80; controles simultáneos; salas; IA; vueltas 3/6/9; clasificación, torneo y podio. El cambio artístico no rediseña estas reglas.

Dirección aprobada: garaje Motorsport, Velocidad Reactor, Curvas Aventura/jungla, Horquillas taller/desierto, Gran Final Neón, Juguete divertido con mejores materiales.

## Situación inicial comprobada

- Godot 4.5.1, renderer Compatibility para Web y Mobile para aplicación.
- Web29 es la versión habitual. La prueba Motorsport está publicada por separado y su código está en revisión (PR2).
- El garaje de esa prueba usa una ilustración de fondo; no acredita calidad de entorno 3D. Los vehículos/escenarios siguen siendo mayormente geometría sencilla.
- Faltan recursos 3D de calidad con UV, texturas PBR y versiones optimizadas.
- Blender está disponible en el entorno. Su disponibilidad no significa que exista ya un vehículo modelado y terminado.
- Android requiere preparar permisos de red, exportación e instalación y firma para distribución. No existe preset iOS; la vía nativa requiere macOS/Xcode y firma.
- No hay mediciones en teléfonos físicos. Las pruebas de navegador y el renderer software validan comportamiento, no calidad/rendimiento en iPhone.

## Equipo y responsabilidades

| Frente | Responsable | Trabajo |
|---|---|---|
| Coordinación | Agente principal | Alcance, tareas, dependencias, integración y registro de decisiones |
| Arte y recursos | Agente de arte | Inventario y candidatos reales, licencias, materiales y coherencia visual |
| Tecnología | Agente técnico | Importación, iluminación, perfiles, medidas y decisión de motor |
| Interfaz | Agente UX | Menús, garaje, HUD, flujo de salas y accesibilidad táctil |
| Entrega y QA | Agente de entrega | Criterios, regresiones, evidencias y preparación de publicación |
| Acabado artístico | Por determinar | Modelado/texturas/composición si los paquetes disponibles no bastan |
| Aceptación visual | Usuario | Valorar el juego real frente a las referencias |

Los agentes trabajan en tareas independientes y revisión cruzada. Más agentes no sustituyen modelos adecuados, trabajo artístico ni teléfonos de prueba. Se amplía el equipo cuando existe una tarea independiente y concreta.

## Fases, dependencias y puertas de aceptación

| Fase | Entrega concreta | Condición para avanzar |
|---|---|---|
| 0. Definición | Referencias anotadas, plataforma principal, dispositivos, presupuesto y lista de conservación | Objetivo evaluable por componente; decisiones pendientes registradas |
| 1. Selección | 2–3 candidatos reales de vehículo, kit industrial y materiales, con licencia/formatos/precio verificados | Recursos abiertos en Godot y capaces de acercarse al objetivo; compra solo autorizada |
| 2. Muestra | Un vehículo terminado, garaje 3D y tramo Reactor de 200–300m | Comparación de capturas/vídeo reales, mismos encuadres; aprobación del usuario |
| 3. Viabilidad móvil | Compilación y perfiles probados en Android/iPhone representativos | Calidad aceptada y fluidez medidas; resolver limitaciones antes de ampliar |
| 4. Producción | Extender el nivel aprobado a los cinco circuitos y todas las pantallas | Revisión individual visual/funcional y presupuesto de rendimiento |
| 5. Integración | IA, online, torneo, podio, controles y actualización estable | Partida real y regresiones, aceptación visual y publicación autorizada |

Fases 2 y 3 se iteran juntas; no se acaba arte caro antes de medir. Si la muestra no alcanza el objetivo, se cambian los recursos o el pipeline, no se repite decoración de baja calidad en todo el juego.

## Primer bloque de trabajo ejecutable

| ID | Tarea | Depende de | Evidencia de cierre |
|---|---|---|---|
| P01 | Inventariar recursos actuales y referencias visuales | — | Lista de qué conservar/reemplazar y objetivos por imagen |
| P02 | Definir dispositivos, navegador/app y presupuesto | — | Respuestas o pendientes explícitos |
| P03 | Buscar vehículos, kit industrial y materiales | P01 | Fichas con origen, capturas de recursos reales, licencia y precio |
| P04 | Importar candidatos en escena mínima | P03 | glTF/GLB funcional, materiales, normales, escala, pivotes y tamaño |
| P05 | Seleccionar vehículo/kit | P02/P04 | Comparativa revisable; autorización si hay compra |
| P06 | Preparar UV, texturas y LOD en Blender | P05 | Fuentes .blend, export GLB, mapa de materiales y licencia |
| P07 | Construir garaje 3D + tramo Reactor persistido | P06 | Mismo vehículo en ambos; iluminación horneable y escenas guardadas |
| P08 | Montar UI del primer recorrido completo | P07 | Inicio → piloto → partida/sala → carrera → resultados |
| P09 | Preparar compilación, acceso al teléfono, capturar y perfilar | P02/P07/P08 | Vídeo y medidas con modelo/SO/calidad documentados |
| P10 | Revisar calidad y elegir siguiente paso | P09 | Aprobación o defectos concretos; motor decidido por evidencia |

## Cómo producir los recursos

Blender: escala, pivotes, malla, UV, normales, colisiones simples, LOD y exportación GLB; conservar los archivos fuente. Materiales: albedo, normal y rugosidad/metal/AO cuando aporten valor; empezar con 1K y reservar 2K para protagonistas si las medidas lo permiten. Compartir materiales/atlas.

Godot: escenario persistido para hornear iluminación, luz principal y sombras limitadas, reflejos preparados, LOD y distancia de dibujo. Separar malla visible de colisión y competición. La ilustración de un garaje puede ser un recurso decorativo, pero no reemplaza la muestra de garaje 3D.

IA: conceptos, gráficos y borradores de recursos; no presentar imágenes generadas como capturas del motor. Los modelos generados necesitan revisar topología, UV, materiales y optimización.

## Aceptación visual

Preparar tres comparativas: vehículo en garaje, persecución en carrera y pantalla de menú. Para cada una puntuar por separado: silueta/detalle del modelo; materiales; iluminación/reflejos; entorno; composición/cámara; interfaz. Incluir una toma normal mientras se juega, no solo una cámara de exhibición.

El usuario acepta el resultado real antes de producir los otros ambientes. Una media de notas no oculta un defecto grave: si vehículo o escenario no alcanzan la dirección acordada, esa muestra no pasa. Caras y motes siguen reconocibles; los cuerpos originales aparecen en selección.

## Aceptación técnica propuesta, pendiente de dispositivos

- Mínimo inicial propuesto: perfil estable de 30 FPS; 60 es un objetivo adicional, no una promesa.
- Documentar tiempos de fotograma p50/p95/p99 y porcentaje >33.3/50ms. Objetivo inicial p95 ≤40ms y sin parones sostenidos >100ms tras carga; ajustarlo al dispositivo acordado.
- Medir 10–15 minutos, memoria máxima, carga, tamaño de descarga y calentamiento; anotar resolución/calidad/modelo/SO.
- Probar 1, 8 y 16 corredores con efectos, armas, boost, rampas y sombras.
- Android real y iPhone real; Safari/WebKit de escritorio no sustituye estas pruebas.
- Online: RTT, jitter, desconexiones y tiempos de fotograma separados. Un servidor mejor no genera mejores gráficos.
- Controles: cinco contactos simultáneos, cancelación, orientación, interrupción/reanudación y zonas seguras.
- Polígonos, texturas y draw calls se presupuestan después de perfilar, no como garantía universal.

## Motor y distribución

Mantener Godot durante la muestra; no migrar por una imagen de referencia. Si una limitación concreta impide calidad y rendimiento tras optimizar, comparar una microescena en Unity URP con los mismos modelos, materiales, cámara y carga. Revisar soporte web móvil y licencia de la versión elegida. Migración incluye física, controles, bots, red y torneo: esfuerzo por estimar, no paso automático.

Dos posibles productos: aplicación instalada con mayor detalle y Web ligera, o un único producto Web dentro de sus límites. Decisión pendiente del usuario. No prometer distribución nativa iPhone hasta verificar herramienta, firma y acceso al dispositivo.

## Presupuesto y calendario

No se ha autorizado ninguna compra ni contratado artista. No hay precios verificados en este plan. Comparar tres vías: recursos gratuitos de licencia comprobada; paquetes comerciales adaptados; arte a medida. Presupuestar recursos, adaptación artística, pruebas/dispositivos, distribución y mantenimiento por separado. Blender/Godot no requieren comprar una licencia de uso; servicios, paquetes y distribución pueden tener costes.

Estimación orientativa de esfuerzo especializado, no fecha de entrega de agentes: muestra con paquetes adecuados, 2–5 semanas-persona; recursos protagonista/kit a medida, 5–10 semanas-persona; otros ambientes, 2–4 semanas-persona cada uno. Son rangos de alta incertidumbre, pendientes de selección y medición. No sumar ni convertir en calendario hasta saber recursos, personal y disponibilidad.

## Riesgos y límites

Recursos de estilos incompatibles; licencias que no permitan distribución; memoria excesiva; efectos caros; diferencias entre navegador y aplicación; falta de dispositivo/iOS toolchain; integración poco cuidada de caras fotográficas; regresiones online. Mitigación: muestra pequeña, evidencia real y pruebas antes de extender.

Este plan no modifica ni publica el juego, no compra recursos y no añade música (sigue aplazada). La versión habitual se sustituirá cuando el resultado real y las pruebas cumplan los criterios acordados.

## Decisiones pendientes

1. Prioridad: aplicación con Web ligera o solo navegador.
   Para pruebas nativas: permisos/exportación Android y acceso a teléfono; iOS requiere macOS/Xcode y firma disponibles.
2. Modelos concretos de Android/iPhone para prueba.
3. Presupuesto máximo para recursos y trabajo artístico.
4. Candidatos de recursos con precios y licencias verificados.
5. Disponibilidad de artista si los candidatos no alcanzan la calidad.

## Entregables completos de interfaz

| Pantalla | Entrega y comprobación |
|---|---|
| Inicio | Carrera, torneo, amigos y ajustes; estado de carga claro |
| Garaje/pilotos | 16 retratos/cuerpos originales, motes, kart 3D y selección inequívoca |
| Preparar carrera | Circuito, IA/amigos y 3/6/9 vueltas; reglas del anfitrión visibles |
| Salas/lobby | Lista, capacidad, circuito/estado, crear/entrar, código alternativo, participantes y listos |
| Torneo | Tres vueltas de clasificación por mejor vuelta, cuatro carreras y puntos acumulados |
| Resultados/podio | Lista completa, tiempos/puntos, tres pilotos correctos, copa y medallas legibles |
| Ajustes | Sonido y calidad; cierre visible y automático al cambiar de fase |
| HUD/pausa | Marcador compacto; izquierda joystick; derecha atrás/salto/disparo abajo, freno arriba; salto/disparo mayores |

Validar 16:9, 19.5:9, 20:9 y tablet 4:3, zonas seguras, desplazamiento en listas y texto en teléfono real. Objetivos táctiles de al menos 48 unidades lógicas como propuesta, comprobados físicamente. Ningún panel tapa resultados ni podio. Distinguir servidor desconectado, sala llena y carrera iniciada. Evitar solicitudes duplicadas y liberar entradas al cancelar, perder foco o pausar.

La matriz funcional incluye IA y amigos, regreso desde resultados, reconexión y desconexión del anfitrión. Inventariar comportamientos actuales para que el rediseño no introduzca reglas de red sin revisión.
