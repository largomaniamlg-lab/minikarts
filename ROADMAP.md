# MiniKarts — hoja de ruta

Objetivo: juego Android completo, original y divertido, dirigido desde Samsung y desarrollado principalmente en Codex Cloud. Estado inicial verificado: [MASTER_CONTEXT.md](MASTER_CONTEXT.md), 11 de octubre de 2026. Criterios concretos: [BACKLOG.md](BACKLOG.md).

## Fase 1 — Auditoría y estabilidad (prioridad máxima)

- Hecho: inspección de escenas, scripts, recursos, configuración y exportación Android; importación Godot, suite y arranque del web existente; documentación técnica; fuentes en `godot/` y comando `bash scripts/test.sh`.
- Pendiente: corrección de controles de escritorio, exportación web reproducible y comprobación de correspondencia fuente/artefacto.
- Salida: base revisable y verificable, sin regresiones. El arranque del web actual no acredita una compilación nueva.

## Fase 2 — Conducción y controles

Ajustar dirección y joystick a partir de pruebas reales; suavizar aceleración, frenada y reversa; evaluar derrapes, salto, cámara y entradas simultáneas. Añadir regresiones. El doble salto no existe actualmente: acordar su diseño antes de incorporarlo.

Salida: conducción natural y divertida, confirmada en móvil físico además de pruebas automáticas.

## Fase 3 — Circuito y jugabilidad

Revisar pista, obstáculos y cajas; ampliar pruebas de checkpoints y vueltas; añadir cuenta atrás; mejorar cronómetro y tiempos existentes, recuperación y pantalla de resultados. Validar una carrera completa de principio a fin.

Salida: carrera individual completa con salida, llegada y reinicio claros.

## Fase 4 — Identidad visual

Definir con el director creativo el estilo original; mejorar kart, materiales, iluminación, decoración, efectos, menús y HUD móvil. Medir el coste en dispositivos objetivo. Usar recursos originales o autorizados.

Salida: identidad coherente propia, legible y optimizada.

## Fase 5 — Sonido y velocidad

Añadir motor, frenos/derrapes, saltos/aterrizajes, disparos/impactos, cajas y cuenta atrás; música original o licenciada y efectos de velocidad. Revisar mezcla, tamaño y rendimiento.

Salida: experiencia dinámica con audio adecuado para móvil.

## Fase 6 — Rivales e IA

Crear karts rivales, rutas, navegación, velocidad, adelantamientos, recuperación y dificultad; integrarlos en carreras de tres vueltas.

Salida: carreras contra oponentes con comportamiento comprobable.

## Fase 7 — Contenido y progresión

Nuevos circuitos y karts originales, características de conducción, selección, desbloqueos, mejores tiempos persistentes, estadísticas y dificultad progresiva.

Salida: contenido que motive seguir jugando.

## Fase 8 — Android y publicación

Configurar SDK, JDK y plantillas fijadas; exportar APK reproducible; verificar arquitecturas, instalación, arranque, firma y actualización; probar rendimiento y UI táctil, automatizar compilación y preparar distribución.

La preparación básica Android puede adelantarse tras estabilizar las fuentes para facilitar las fases 2 y 3. ARM64 para Samsung; x86_64 para el emulador conocido. No publicar ni distribuir sin autorización.

Salida: versión Android instalable y estable, con evidencia por dispositivo y artefacto.

## Orden inmediato

1. MK-01: completada; fuentes versionadas y entrada reproducible para pruebas.
2. MK-02: discrepancias de controles de escritorio.
3. MK-03: compilación web reproducible y prueba de arranque.
4. MK-04: exportación Android ARM64/x86_64.
5. MK-05: evaluación en Samsung y carrera completa.

MK-01 autorizada e implementada. Siguiente tarea recomendada: MK-02; no publicar sin autorización.

## Actualización del siguiente ciclo

MK-02 y MK-03 implementadas y verificadas localmente: controles de escritorio y exportación web reproducible. No publicadas. Siguiente prioridad: decidir si publicar esta web para evaluación en Samsung o preparar Android. Multijugador privado para cuatro jugadores requiere una fase propia de red, servidor/salas, sincronización y pruebas de latencia (MK-13), todavía por acordar.

## Prioridad elegida: multijugador privado

El usuario adelanta MK-13 para carreras con tres amigos, incluyendo trompos por disparos y protección. Primera implementación local verificada con servidor de autoridad y cuatro clientes web. Las mejoras artísticas quedan aplazadas. Hito siguiente: seleccionar y desplegar alojamiento WSS, configurar cliente automáticamente y probar una carrera desde cuatro móviles. Borrador gratuito en render.yaml; sin contratación ni publicación automática.

## Ajuste de prioridad: elementos del grupo antes del servidor

El usuario elige alojamiento gratuito y pide primero MK-14: tres pilotos adicionales, dormilón neutral móvil, árboles de piernas y proyectiles de foto. Implementación local y pruebas de reglas preparadas; revisar visualmente las caras y el dormilón ilustrado provisional antes de publicar. Después retomar alojamiento WSS gratuito y probar desde cuatro teléfonos. La foto original del dormilón no se pudo recortar con el generador; no presentar el sustituto como esa fotografía.

## Prioridad actual: modos elegibles y carreras con el grupo

Selector visual de cuatro caras y proyectiles a 1,875 veces: implementados localmente. Carrera offline contra tres bots, salida, tres vueltas, clasificación y revancha: implementación local en verificación. Entrenamiento individual conservado. Antes de publicar, revisar pruebas y exportación del ciclo.

Siguiente dependencia: cuenta Render desde el Samsung para desplegar el servidor gratuito preparado. Obtener URL WSS, exportar cliente configurado y probar carrera real con cuatro teléfonos. Después ajustar conducción/latencia online y dificultad de IA según partidas reales; no añadir contenido antes de estabilizar estas carreras.
