# Elementos del grupo

Las imágenes fueron preparadas con el generador a partir de las fotos aportadas por el usuario, salvo el dormilón provisional. Los recortes procesados pueden diferir del original; revisar su parecido y contorno antes de publicar. Los archivos PNG conservan transparencia y Godot los presenta como sprites dentro del escenario 3D.

| Archivo | Uso y origen |
| --- | --- |
| drivers/friend_face.png | Kikoso, cara que ya estaba implementada. |
| drivers/makeup_face.png | Largo, cara superior con maquillaje de la primera foto nueva. |
| drivers/smile_face.png | Sipollo, cara inferior de la primera foto nueva. |
| drivers/beard_face.png | Antocino, cara de la segunda foto nueva. |
| memes/legs.png | Doce decoraciones de 6 m de altura fuera de pista, basadas en la cuarta foto. |
| memes/projectile.png | Proyectil de 1,5 m de altura basado en la quinta foto; colisión por raycast existente. |
| memes/jordan.png | Jordan con bóxers azul oscuro y almohada, recorte transparente del ejemplo aprobado por el usuario. Sprite de 7,5 m de ancho; tamaño ×1,875 respecto al anterior. |
| memes/sleeper.png | Dibujo provisional de un adulto vestido con pijama y almohada. No es la foto del amigo: el generador rechazó el recorte solicitado de la tercera imagen. |

Las caras permanecen orientadas a cámara y conservan su expresión fija; el cuerpo del piloto se anima aparte. Seleccionar antes de entrar a una sala. El neutral actual (Jordan) usa un área de contacto de 6,5625 × 2,15625 × 4,3125 m, oscila 6,5 m a cada lado del centro de su sección y se reinicia con la carrera. No se destruye con disparos. Las piernas carecen de colisión; se conservan los pinos y obstáculos anteriores.

El nuevo material deriva de la imagen corregida aportada por el usuario y del primer ejemplo aprobado. Se cancelaron las dos variantes adicionales por indicación del usuario; no son necesarias. El recurso provisional sleeper.png se conserva como antecedente, pero no se usa en la escena.
