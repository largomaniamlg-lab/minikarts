# Continuar MiniKarts en tu portátil Windows

Esta guía prepara Codex local para ejecutar Blender por scripts. No da control remoto de la interfaz ni transfiere automáticamente el historial del chat. No se ha instalado ni probado nada en tu portátil desde Cloud.

## 1. Descargar la copia ligera del proyecto

Descarga `MiniKarts-continuar-local.zip` del enlace que acompaña la guía. En el Explorador, botón derecho → Extraer todo. Usa una carpeta sencilla, por ejemplo `C:\MiniKarts-local`. Comprueba que dentro aparecen `godot`, `docs`, `scripts` y `MASTER_CONTEXT.md`; evita quedarte en una carpeta exterior vacía.

Este paquete no incluye .git, cachés, credenciales ni paquetes web antiguos. Es una copia de fuentes, no un instalador. El historial Git puede añadirse después clonando https://github.com/largomaniamlg-lab/minikarts y seleccionando art/motorsport-reactor. No mezclar copia y checkout sobrescribiendo cambios sin revisar.

## 2. Instalar Node.js y Codex CLI

Abre https://nodejs.org/ y descarga la versión LTS para Windows. Instala con las opciones normales. Después abre PowerShell desde el menú Inicio, sin administrador como primera opción.

Ejecuta los comandos de uno en uno:

```powershell
node --version
npm.cmd --version
npm.cmd install -g @openai/codex
```

Cierra y abre PowerShell. Comprueba:

```powershell
codex.cmd --version
```

Si no reconoce `codex.cmd`, prueba:

```powershell
& "$env:APPDATA\npm\codex.cmd" --version
```

Si `npm` o `codex` dan un error sobre scripts deshabilitados, utiliza sus nombres `.cmd` de arriba; no cambies globalmente la política de PowerShell. Si hay otro error, copia su texto sin claves ni contraseñas para diagnosticarlo.

Fuente oficial de instalación npm y autenticación: https://github.com/openai/codex . El programa se instala sin pagar por una licencia; el uso del agente depende del acceso y límites de tu cuenta ChatGPT. No contratar API ni comprar créditos para este proyecto.

## 3. Iniciar dentro de la carpeta del proyecto

En PowerShell:

```powershell
Set-Location 'C:\MiniKarts-local'
Get-ChildItem
codex.cmd
```

Si usaste otra carpeta, cambia la ruta. El listado debe mostrar `godot`, `docs` y `scripts`. Si `codex.cmd` no está en PATH, usa la ruta completa de la sección anterior.

Elige **Sign in with ChatGPT** e inicia sesión en el navegador con tu cuenta habitual. No elijas API key. Completa las instrucciones de configuración/permisos que muestre esa versión. Trabaja en LOCAL; no envíes esta tarea a Cloud. Aprueba las operaciones concretas del proyecto cuando corresponda; no necesitas acceso irrestricto al ordenador.

El CLI es una conversación dentro de la terminal. También existe la extensión oficial de Codex para VS Code como alternativa; no hace falta instalar ambas para empezar.

## 4. Pegar el prompt de traspaso

Abre `docs\local\PROMPT_TRASPASO.txt`, copia todo y pégalo en Codex. El agente local debe empezar comprobando la instalación y generar una prueba de Blender. No conoce automáticamente esta conversación. Adjunta las imágenes originales de referencia en la nueva sesión si se solicitan; el texto no transporta las fotos del chat.

## 5. Verificar acceso real a Blender

El agente debe encontrar la ruta de `blender.exe`, consultar su versión y ejecutar nuestro script de prueba. Si quieres entender el comando, será parecido a este: la ruta y la carpeta de salida las debe ajustar a tu instalación.

```powershell
$blenderExe = 'C:\Program Files\Blender Foundation\Blender VERSION\blender.exe'
$probeOutput = Join-Path (Get-Location) ('local-output\probe-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& $blenderExe --background --factory-startup --python 'scripts\local\blender_access_probe.py' -- --output $probeOutput
```

`VERSION` es un marcador, no una ruta que puedas copiar literalmente. El script se niega a reutilizar una carpeta existente, y trabaja en un proceso nuevo. Deja:

- `probe.blend`: cubo amarillo de diagnóstico.
- `probe.glb`: exportación para importar.
- `report.json`: versión de Blender y propósito.

Abre `probe.blend` en Blender con Archivo → Abrir. Ver un cubo acredita acceso/exportación, NO calidad artística. El agente debe comprobar además que el GLB se puede importar.

## 6. Continuar el arte y el juego

Usar Blender para preparar modelos y Godot 4.5.1 para montar/probar el juego. Instalar Godot si falta desde su sitio oficial https://godotengine.org/download/archive/ . Importar `godot\project.godot`; no actualizar de versión el proyecto sin revisar compatibilidad. Tu versión local de Blender puede diferir de la Cloud: guardar copias y comprobar exportación GLB; un .blend nuevo puede no abrir bien en un Blender anterior.

Presupuesto actual: 0 €. Buscar recursos gratuitos de licencia verificada. Primero kart, garaje 3D y tramo Reactor; luego medir/valorar y extender. Los posibles 30 € futuros no autorizan compras.

Los agentes de Cloud no continúan automáticamente en el portátil. La nueva sesión puede repartir tareas si tiene esa función. No modificar/publicar Web29 ni desplegar Render para comprobar Blender.

## Si algo falla

- No reconoce Node/npm/Codex: cerrar/reabrir terminal y comprobar instalación/PATH.
- Permisos: usar el flujo normal de aprobación de Codex para la tarea local; no habilitar acceso general ni cambiar protecciones globales.
- No encuentra Blender: revisar su instalación o usar Abrir ubicación del archivo en su acceso directo; proporcionar la ruta de blender.exe, no una contraseña.
- No aparece Godot: completar esa instalación después de la prueba de Blender.
- Inicio de sesión o límite de cuenta: resolver con tu cuenta existente; no contratar una API como solución automática.

Puedes volver a este chat con el texto del error o una captura. No compartas claves, contraseñas ni archivos de credenciales.
