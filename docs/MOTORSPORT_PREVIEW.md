# Motorsport / Reactor — primera prueba jugable

La dirección combina el garaje Motorsport, Reactor en Velocidad, Aventura en Curvas,
taller de desierto en Horquillas y Neón en Gran Final. Juguete mantiene sus bromas.

Esta entrega es una implementación inicial, no una réplica exacta de las imágenes
conceptuales. Las capturas en screenshots/motorsport son del navegador ejecutando
el juego. El taller de fondo es una ilustración original generada para el menú;
no representa una escena 3D navegable. El kart mostrado encima sí es 3D y gira.

## Implementado

- Menú y selección con materiales oscuros, acento amarillo, fuente OFL existente,
  taller de fondo, todos los retratos originales y preview 3D por piloto.
- Chasis original de tubos, llantas con radios, muelles, escape y carrocería
  más baja. Un mesh combinado para metal, ruedas MultiMesh independientes.
- Luz continua, acabado metálico, brillo moderado y grano de superficie.
- Reactores con bandas cyan, tuberías, cables, consolas y plataformas;
  rocas y cascadas decorativas en jungla, talleres detallados en desierto,
  ventanas y carteles en ciudad, nuevas gradas en Juguete.
- Tema coherente también en salas, sonido y marcador. Cámara algo más baja.
- Corrección de actualización del color online usando parámetros ShaderMaterial.

## Conservado

Los 16 amigos, sus caras y cuerpos, Jordan, obstáculos y saltos funcionales,
velocidad base 65 / boost 80, controles multitáctiles, salas, IA, vueltas 3/6/9,
clasificación y torneo. La decoración añadida no modifica colisiones ni trazado.

## Validación

La batería nativa completa pasó, incluidas las cuatro carreras con 16 bots.
Después de ajustes finales se repitieron menú e integración visual. El navegador
comprobó cuatro circuitos y clasificación, y se comprueban controles táctiles,
selección en tres tamaños, creación de sala y enlace compartido.

## Distancia respecto al concepto

Aún faltan entornos modelados con mayor riqueza, texturas artísticas por objeto,
reflejos de entorno y composición de iluminación comparable a las referencias.
La cascada es una representación geométrica sencilla. No hay reflejos de suelo
mojado ni simulación de agua. Las llantas se animan; los radios combinados del
chasis son decoración fija. No se ha medido rendimiento en móvil físico ni se
promete 60 FPS. Renderizar bien en software valida funcionalidad, no rendimiento.

La publicación habitual sigue en Web29. La prueba separada permite comparar
antes de reemplazarla, respetando la condición del usuario sobre fidelidad.

Resultado final de navegador: cinco contactos independientes, tres tamaños de
menú, sala real y enlace compartido, cuatro circuitos y clasificación: PASS.
Arranque de la exportación final y comprobación de assets: PASS.
Las capturas de carrera corresponden al pase anterior al último ajuste de grano:
la prueba publicada reduce ese grano de 0.2 a 0.045, manteniendo los mismos modelos.

Prueba pública: https://largomaniamlg-lab.github.io/minikarts/prueba-motorsport.html
Código en revisión: https://github.com/largomaniamlg-lab/minikarts/pull/2
