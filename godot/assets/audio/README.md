# Audio de MiniKarts

- `race_music.ogg`: composición original generada para MiniKarts, groove arcade de 64 segundos a 120 bpm. Se reproduce en bucle. No utiliza muestras de terceros.
- `engine.wav`, `brake.wav`, `jump.wav`, `land.wav`, `shoot.wav`, `impact.wav`, `box.wav`, `spin.wav`, `tick.wav`, `go.wav`: síntesis original para el proyecto, mono 22.05 kHz.
- `finish.ogg`: Kenney Music Jingles, `8-Bit jingles/jingles_nes_0.ogg`, licencia CC0 1.0. Página original: https://kenney.nl/assets/music-jingles . Copia descargada de https://github.com/Boyquotes/kenney-music-jingles-for-godot, commit `1312c1a8ab2b5830136a5f53ea8c570389bd0808`. Licencia preservada en `CC0-Kenney.txt`. La licencia permite distribución y modificación sin atribución obligatoria; se conserva la procedencia.

Reproducir la síntesis: `python3 scripts/generate-audio.py`; convertir la música con `ffmpeg -i godot/assets/audio/race_music.wav -c:a libvorbis -q:a 3 godot/assets/audio/race_music.ogg` y retirar el WAV musical intermedio.

El servidor no inicializa audio. Música y efectos tienen controles independientes, silencio global y preferencias en `user://sound.cfg`. La salida se pausa al perder el foco. En web, el usuario abre la carrera con un gesto; Safari/iPhone real continúa pendiente de validación.

Selección solicitada para Velocidad: https://teknoaxe.com/Link_Code_3.php?q=1702&genre=Drum_and_Bass . Pendiente de descargar y verificar la licencia de esa ficha exacta. `scripts/import-velocity-music.py` conserva HTTPS/proxy, exige CC BY 4.0 en la página, valida el audio y genera `velocity_music.ogg`, procedencia/hash y créditos. El cambio por circuito está preparado; hasta tener ese archivo mantiene la música original. No se ha sustituido por otra canción de TeknoAXE.
