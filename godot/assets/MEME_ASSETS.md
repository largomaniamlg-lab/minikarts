# Elementos del grupo

Las imágenes fueron preparadas con el generador a partir de las fotos aportadas por el usuario, salvo el dormilón provisional. Los recortes procesados pueden diferir del original; revisar su parecido y contorno antes de publicar. Los archivos PNG conservan transparencia y Godot los presenta como sprites dentro del escenario 3D.

| Archivo | Uso y origen |
| --- | --- |
| drivers/friend_face.png | Piloto 1, cara que ya estaba implementada. |
| drivers/makeup_face.png | Piloto 2, cara superior con maquillaje de la primera foto nueva. |
| drivers/smile_face.png | Piloto 3, cara inferior de la primera foto nueva. |
| drivers/beard_face.png | Piloto 4, cara de la segunda foto nueva. |
| memes/legs.png | Doce decoraciones de 6 m de altura fuera de pista, basadas en la cuarta foto. |
| memes/projectile.png | Proyectil de 0,8 m de altura basado en la quinta foto; colisión por raycast existente. |
| memes/sleeper.png | Dibujo provisional de un adulto vestido con pijama y almohada. No es la foto del amigo: el generador rechazó el recorte solicitado de la tercera imagen. |

Las caras permanecen orientadas a cámara y conservan su expresión fija; el cuerpo del piloto se anima aparte. Seleccionar antes de entrar a una sala. El neutral usa un área de contacto de 3,5 × 1,15 × 2,3 m, oscila 6,5 m a cada lado del centro de su sección y se reinicia con la carrera. No se destruye con disparos. Las piernas carecen de colisión; se conservan los pinos y obstáculos anteriores.
