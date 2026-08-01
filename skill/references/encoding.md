# Codificación, rutas y entornos

## Codificación del manual oficial

El archivo `C:\Siigo\ExcelSIIGO-Ayuda.LOG` está guardado en **Windows-1252**
(cp1252). Los acentos y eñes se ven como `A�o`, `Funci�n`, `Categor�a`, etc.
si lo abres con un visor que asume UTF-8.

**Este skill**:

- Normaliza el manual a UTF-8 (`references/excel-siigo-help.md`).
- Los wrappers imprimen **siempre UTF-8** en stdout.
- El .LOG crudo que genera `EXCELSIIGO.exe` sigue siendo cp1252 — `parse-log.py`
  lo decodifica correctamente al leerlo.

## Rutas con espacios, tildes o caracteres especiales

Windows acepta espacios y tildes en rutas sin problema. El truco está en
cómo las pasas al binario desde Bash/PowerShell:

### Bash (Git Bash / MSYS / WSL)

```bash
# CORRECTO: entre comillas dobles
"/c/Siigo/EXCELSIIGO.exe" "C:/SIIWI01/" 2024 GETMOV "L" ...

# INCORRECTO: sin comillas (falla con espacios)
/c/Siigo/EXCELSIIGO.exe C:/Mi Empresa/ 2024 GETMOV L ...
```

Los wrappers del skill **siempre** quoten los argumentos, así que en
condiciones normales no tienes que preocuparte.

### PowerShell

```powershell
& "C:\Siigo\EXCELSIIGO.exe" "C:\Mi Empresa\" 2024 GETMOV L ...
```

### Python

```python
import subprocess
subprocess.run([
    r"C:\Siigo\EXCELSIIGO.exe",
    r"C:\Mi Empresa\",
    "2024", "GETMOV", "L",
    usuario, clave, log_path,
    # ... resto de params
], check=True)
```

## Rutas largas (>260 chars)

Windows habilita por defecto el límite MAX_PATH de 260 caracteres. Si tu
ruta empresa o tus archivos .xlsx están很深, tienes dos opciones:

1. **Preferida**: usar la versión moderna de `LongPathAware` (Windows 10
   1607+). Activar con:

   ```powershell
   Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
   ```

2. **Alternativa**: usar rutas relativas o mover la empresa a una ruta más
   corta (`C:\SIIWI01\` en lugar de `C:\Users\juan.perez\Documents\Empresas\Mi Empresa S.A.S 2024\`).

## Entornos de ejecución

| Entorno            | ¿Soporte?    | Notas                                                                |
|--------------------|---------------|----------------------------------------------------------------------|
| Windows nativo     | ✅ Recomendado | PowerShell o CMD. Ejecutar con la sesión del usuario que abre SIIGO. |
| Git Bash (MSYS)    | ✅ Recomendado | Los wrappers asumen este shell por defecto.                          |
| WSL (Ubuntu/etc)   | ⚠️ Limitado   | Sólo si llamas al .exe vía `cmd.exe /c` o montando `/mnt/c/...`.     |
| Wine               | ❌ No soportado| El .exe usa DLLs nativas Win32 + ODBC a SQL Anywhere, no portable.   |
| macOS / Linux      | ❌ No soportado| Usar RDP/PSExec a un Windows con SIIGO.                              |
| Docker Windows     | ⚠️ Avanzado   | Requiere contenedor Windows con licencia y empresa montadas.        |

## Variables de entorno vs argumentos

Los wrappers aceptan ambas formas. La prioridad es:

1. Argumento explícito al wrapper (`--salida`).
2. Variable de entorno (`SIIGO_*`).
3. Default hardcodeado en el wrapper.

Esto permite:

```bash
# Caso típico: defines SIIGO_* una vez
export SIIGO_EMPRESA="C:/SIIWI01/"
export SIIGO_USUARIO="admin"
# (clave via export SIIGO_CLAVE=... o prompt)

# Y luego sólo pasas los params específicos
bash scripts/excel-siigo.sh getmov --fini 0501 --ffin 0531 --salida out.xlsx
```

## Acentos en la clave del usuario

Las claves SIIGO son **siempre de 8 caracteres alfanuméricos** — sin acentos,
espacios ni caracteres especiales. La codificación de la clave no es un
problema en la práctica.

## Zonas horarias y horario de verano

`EXCELSIIGO.exe` no usa la zona horaria del sistema para fechar; usa el reloj
interno de la base SIIGO. Si tu servidor de base de datos está en otra zona,
verifica que la hora del servidor sea correcta antes de extraer movimientos.
