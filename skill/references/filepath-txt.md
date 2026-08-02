# filepath.txt — Cómo SIIGO Pyme localiza las empresas

## ¿Qué es?

`filepath.txt` es un archivo de texto plano que SIIGO Pyme crea **dentro de
la carpeta de instalación de cada copia del ejecutable** (`C:\Siigo\`,
`C:\Siigo2\`, etc.). Contiene la ruta UNC/absoluta de la carpeta de la
empresa a la que esa instalación está apuntando.

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

Si el CLI devuelve `070 Empresa no se encuentra instalada`:

```bash
# 1. Ver filepath.txt
cat /c/Siigo/filepath.txt
cat /c/Siigo2/filepath.txt

# 2. Verificar que la ruta destino existe
ls "<ruta_del_filepath.txt>"

# 3. Si es una unidad de red, verificar que está montada
#    en PowerShell:
#    Get-PSDrive | Where-Object {$_.DisplayRoot -like '*inmunotek*'}
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
