# siigo-pyme-excel

> Skill para que un agente IA pueda invocar el CLI `ExcelSIIGO.exe` de
> **SIIGO Pyme** (Colombia) y automatizar la importación/exportación de
> datos entre SIIGO y archivos Excel.

## ¿Qué hace?

`SIIGO Pyme` es el software contable más usado por PyMEs colombianas. Incluye
un CLI de Windows (`EXCELSIIGO.exe`) con **46 funciones** para mover datos
entre la base SIIGO y archivos `.xlsx`:

- `GET*` → extraer datos de SIIGO a Excel.
- `PUSH*` → importar datos de Excel a SIIGO.

Este skill envuelve ese CLI con:

- **Wrappers** en Bash, PowerShell y Python que validan la entrada,
  ejecutan el .exe y devuelven **JSON** estructurado.
- **Validador de prerrequisitos** (`check-prereqs.sh`).
- **Parser de logs** que decodifica correctamente el Windows-1252 que
  emite el CLI.
- **Generador de plantillas .xlsx** vacías para que el usuario sepa qué
  columnas llenar antes de un PUSH.
- **Documentación completa** del manual oficial (incluido como
  referencia) y un catálogo razonado de las 46 funciones.

## Instalación

### Como skill para tu agente IA

Copia la carpeta `skill/` a la ruta de skills de tu agente y referénciala
por nombre. Compatible con cualquier agente que soporte skills tipo
Hermes / Claude / Pi (frontmatter YAML con `name` + `description`).

### Uso independiente (sin agente)

```bash
git clone https://github.com/<TU-USUARIO>/siigo-pyme-excel-skill.git
cd siigo-pyme-excel-skill/skill
export SIIGO_EXE='C:\Siigo\EXCELSIIGO.exe'
export SIIGO_EMPRESA='C:\SIIWI01\'
export SIIGO_USUARIO='admin'
export SIIGO_CLAVE='12345678'
bash scripts/check-prereqs.sh
bash scripts/excel-siigo.sh list
```

## Prerrequisitos

- **Windows** (el .exe es PE32 nativo). Wine experimental.
- **SIIGO Pyme** instalado con la empresa ya creada.
- **Licencia SIIGO** vigente (la valida el propio CLI).
- **Python 3.8+** (sólo para `parse-log.py` y `build-xlsx-template.py`).
- **PowerShell 5+** (sólo si usas el wrapper .ps1).

## Ejemplos

```bash
# 1. Listar funciones
bash scripts/excel-siigo.sh list

# 2. Generar plantilla vacía de terceros
python scripts/build-xlsx-template.py GETTER \
    --salida assets/templates/GETTER_template.xlsx --offline

# 3. Extraer movimiento contable de mayo 2024
bash scripts/excel-siigo.sh getmov \
    --fini 0501 --ffin 0531 \
    --tipo F --comp 001 002 \
    --nro 00000000001 99999999999 \
    --salida "C:/SIIWI01/Movimiento.xlsx"

# 4. Importar terceros (DESTRUCTIVO: requiere --yes)
bash scripts/excel-siigo.sh pushter \
    --entrada "C:/SIIWI01/Terceros.xlsx" \
    --errores "C:/SIIWI01/LOGS/ErrorTer.xlsx" --yes
```

## Documentación

- **[`skill/SKILL.md`](skill/SKILL.md)** — entry point del skill (léelo primero).
- **[`skill/references/excel-siigo-help.md`](skill/references/excel-siigo-help.md)** — manual oficial completo (961 líneas).
- **[`skill/references/functions-catalog.md`](skill/references/functions-catalog.md)** — las 46 funciones con sus params.
- **[`skill/references/errors.md`](skill/references/errors.md)** — códigos de error y recuperación.
- **[`skill/references/encoding.md`](skill/references/encoding.md)** — Windows-1252, rutas con espacios, Wine.
- **[`skill/references/siigo-pyme-concepts.md`](skill/references/siigo-pyme-concepts.md)** — glosario de términos SIIGO.
- **[`docs/SDD-EXPLORE.md`](docs/SDD-EXPLORE.md)** — análisis técnico del CLI.
- **[`docs/SDD-PROPOSE.md`](docs/SDD-PROPOSE.md)** — propuesta de diseño del skill.

## Aviso importante

⚠️ **Este skill NO es oficial de SIIGO S.A.S.**. Es un envoltorio
independiente sobre un CLI que SIIGO distribuye con su software
propietario. El uso del CLI está sujeto a la licencia de SIIGO Pyme
que hayas adquirido.

SIIGO, SIIGO Pyme y el logo de SIIGO son marcas registradas de
SIIGO S.A.S. (Colombia).

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
