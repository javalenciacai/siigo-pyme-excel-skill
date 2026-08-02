# filepath.txt — Cómo SIIGO Pyme localiza las empresas

## ¿Qué es?

`filepath.txt` es un archivo de texto plano que SIIGO Pyme crea **dentro de
la carpeta de instalación de cada copia del ejecutable** (`C:\Siigo\`,
`C:\Siigo2\`, etc.). Contiene la ruta absoluta de **UNA sola** empresa —
la empresa a la que esa instalación específica del `EXCELSIIGO.exe`
está apuntando.

⚠️ **No es un índice** de todas las empresas disponibles. Si tienes 5
empresas SIIGO en tu organización, cada `EXCELSIIGO.exe` tiene su
propio `filepath.txt` apuntando a SU empresa. El resto de empresas
viven en rutas hermanas (`SIIWI02`, `SIIWI03`, ...) o en otras
unidades, pero **NO aparecen en este archivo**. Para descubrirlas
hay que escanear el filesystem (`C:\SIIWInn\`, `Z:\SIIWInn\`, etc.) o
buscar otros `EXCELSIIGO.exe` en otras carpetas de instalación.

## Formato

```
Z:\SIIWI01\::\\127.0.0.1\inmunotek::
```

Tres campos separados por `::`:

1. **Ruta local / de red** donde vive la empresa (ej. `Z:\SIIWI01\`).
   - El número final (`01`, `02`, `00`) es el ID interno de la empresa.
   - Las empresas siempre viven en una unidad `SIIWInn` (no `SIIWInn\...`).
2. **Ruta UNC del servidor de archivos** del que se monta la unidad
   (ej. `\\127.0.0.1\inmunotek`). Indica la fuente original antes del
   mapeo a letra de unidad.
3. **Campo final vacío** después del último `::` (en este ejemplo).

## Por qué importa

En la mayoría de instalaciones el CLI `EXCELSIIGO.exe` **busca la empresa
en el directorio actual o en una ruta codificada**, pero el comportamiento
real varía según versión. Si el CLI no encuentra la empresa (`070 Empresa
no se encuentra instalada`) pero sabes que existe, lo primero a verificar
es:

1. ¿Existe `<filepath>.txt` en la carpeta donde corre el ejecutable?
2. ¿La ruta que apunta es accesible desde el shell que invoca el wrapper?
3. ¿La letra de unidad (`Z:`) está montada?

## Cómo usarlo desde este skill

El skill `siigo-pyme-excel` por defecto apunta a:

- `SIIGO_EXE = C:\Siigo\EXCELSIIGO.exe` → empresa declarada en
  `C:\Siigo\filepath.txt`
- `SIIGO_EMPRESA = C:\SIIWI01\` → fallback si el CLI no respeta filepath.txt

Si tu `Siigo2\filepath.txt` apunta a otra empresa, basta con:

```bash
export SIIGO_EXE='C:\Siigo2\EXCELSIIGO.exe'
export SIIGO_EMPRESA='Z:\SIIWI02\'    # ruta que aparece en filepath.txt
```

Y el wrapper `excel-siigo.sh` resolverá esa ruta directamente (sin
depender de filepath.txt en tiempo de ejecución).

## Diagnóstico de "no encuentra la empresa"

Si el CLI devuelve `070 Empresa no se encuentra instalada`, el primer
paso es descubrir DÓNDE están tus otras empresas SIIGO. Como
`filepath.txt` no es un índice, escanea el filesystem:

```bash
# 1. Ver filepath.txt de cada instalación
cat /c/Siigo/filepath.txt
cat /c/Siigo2/filepath.txt
cat /c/Siigo3/filepath.txt

# 2. Buscar todas las carpetas de empresa SIIWI* en el sistema
#    (ajusta el path base según tu entorno: C:\, Z:\, etc.)
ls /c/ | grep -iE "SIIWI"        # en C:\
ls /z/ 2>/dev/null | grep -iE "SIIWI"  # en Z: (si está montada)

# 3. Buscar otros EXCELSIIGO.exe instalados
find /c -name "EXCELSIIGO.exe" 2>/dev/null
```

Cada `filepath.txt` te dice a qué empresa apunta ese ejecutable. Una vez
identificada la correcta, configura:

```bash
export SIIGO_EXE='C:\Siigo2\EXCELSIIGO.exe'    # la instalación correcta
export SIIGO_EMPRESA='Z:\SIIWI03\'           # la ruta del filepath.txt
```

## Multi-empresa en el mismo equipo

Si tienes varias empresas (`SIIWI01`, `SIIWI02`, etc.) y solo una carpeta
de instalación de SIIGO, puedes apuntar el mismo `EXCELSIIGO.exe` a
distintas empresas pasando `SIIGO_EMPRESA` por invocación:

```bash
SIIGO_EMPRESA='C:\SIIWI01\' bash scripts/excel-siigo.sh getter ...
SIIGO_EMPRESA='C:\SIIWI02\' bash scripts/excel-siigo.sh getter ...
```

**No necesitas** cambiar `filepath.txt` ni tener varias instalaciones de
SIIGO instaladas.

## Cuándo SÍ quieres múltiples instalaciones

Algunas organizaciones mantienen dos instalaciones paralelas
(`C:\Siigo\` y `C:\Siigo2\`) porque cada una apunta a una empresa o
servidor distinto, o porque manejan distintas versiones del ejecutable.
En ese caso, cada `filepath.txt` apunta a su empresa. El skill funciona
con cualquiera de las dos cambiando `SIIGO_EXE` y `SIIGO_EMPRESA`.
