# Setup

Widgets de escritorio para Windows hechos con [Rainmeter](https://www.rainmeter.net): un reloj grande y un panel lateral estilo iPad con apps, RAM, CPU, música, fecha, progreso del día, volumen, brillo y batería.

Todo corre dentro de un solo proceso de Rainmeter, que gasta unos pocos MB de RAM (nada que ver con los widgets de Windows o las apps hechas con Electron).

```
Setup/
├── @Resources/
│   ├── Variables.inc      ← colores, tamaño, apps y formato de hora
│   ├── Scripts/Panel.lua  ← lógica del panel
│   └── Fonts/             ← fuente Poppins (se carga sola)
├── Reloj/Reloj.ini
├── Panel/Panel.ini
└── actualizar.bat         ← git pull + refrescar
```

## Instalación (una sola vez)

1. Instala **Rainmeter**: https://www.rainmeter.net
2. Instala **Git** si no lo tienes: https://git-scm.com/download/win
3. Abre **PowerShell** y pega esto (clona el repo directo en la carpeta de skins de Rainmeter, aunque tus Documentos estén en OneDrive):

   ```powershell
   git clone https://github.com/breidycaicedo/Setup.git "$([Environment]::GetFolderPath('MyDocuments'))\Rainmeter\Skins\Setup"
   ```

4. Activa los widgets:

   ```powershell
   $rm = "$env:ProgramFiles\Rainmeter\Rainmeter.exe"
   & $rm !RefreshApp; Start-Sleep 2
   & $rm !ActivateConfig "Setup\Reloj" "Reloj.ini"
   & $rm !ActivateConfig "Setup\Panel" "Panel.ini"
   ```

   (También puedes hacerlo a mano: clic derecho al ícono de Rainmeter → *Manage* → `Setup` → `Panel.ini` → *Load*, y lo mismo con `Reloj.ini`.)

5. Descarga los widgets de ejemplo que trae Rainmeter (clic derecho sobre ellos → *Unload skin*).

### Música (opcional)

Para que el widget de música muestre la canción, la portada y los controles, instala el plugin **WebNowPlaying**: descarga el archivo `.rmskin` de https://github.com/keifufu/WebNowPlaying-Rainmeter/releases y ábrelo con doble clic. Funciona con Spotify de escritorio y con lo que suene en el navegador (YouTube, etc.). Sin el plugin, el widget solo dice "Nada sonando".

## Actualizar

Cuando haya cambios en el repo: clic derecho sobre el panel o el reloj → **Actualizar desde GitHub**. O en PowerShell, dentro de la carpeta:

```powershell
git pull
```

y luego clic derecho → *Refresh skin*.

## Personalizar

Clic derecho sobre el panel → **Editar colores, apps y tamaño**. Se abre `Variables.inc` en el Bloc de notas:

- `S=1` → tamaño general. Si se ve pequeño en tu pantalla, prueba `1.2` o `1.4`.
- `FormatoHoraReloj=%I` → reloj de 12 horas (`%H` para 24 horas).
- `App1` … `App8` → nombre, icono, colores y lo que abre cada app.
- `FuenteIconos` → en **Windows 10** cámbiala a `Segoe MDL2 Assets`.

Guarda y dale *Refresh skin*.

## Qué hace cada parte

| Widget | Detalle |
|---|---|
| Apps | 8 accesos directos. Pasa el mouse para ver el nombre. |
| RAM / CPU | Uso en tiempo real, se actualiza cada segundo. |
| Música | Portada, canción, artista y controles (anterior, play/pausa, siguiente). |
| Fecha | Día, fecha y hora. |
| Anillos de colores | Progreso del día (rosa), del mes (verde) y del año (azul). Pasa el mouse para ver los porcentajes. |
| Volumen / Brillo | Haz clic a la altura que quieras o usa la rueda del mouse. El brillo solo funciona en la pantalla del portátil. |
| Batería | Porcentaje; se pone roja por debajo de 20 %. |

## Tips para que no gaste nada

- Apaga los widgets de Windows: *Configuración → Personalización → Barra de tareas → Widgets* (desactivar).
- Para el look limpio de la foto: clic derecho en el escritorio → *Ver* → desmarca *Mostrar iconos del escritorio*.
- Los widgets están en modo "en el escritorio": aparecen cuando minimizas todo (`Win + D`).

## Créditos

Fuente [Poppins](https://github.com/itfoundry/Poppins) bajo licencia SIL Open Font License (ver `@Resources/Fonts/OFL.txt`).
