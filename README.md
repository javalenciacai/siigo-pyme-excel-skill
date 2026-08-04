# siigo-pyme-excel

[![skills.sh](https://skills.sh/b/javalenciacai/siigo-pyme-excel-skill)](https://skills.sh/javalenciacai/siigo-pyme-excel-skill)

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

### Con el CLI de skills.sh (recomendado)

```bash
npx skills add javalenciacai/siigo-pyme-excel-skill --skill siigo-pyme-excel
```

Variantes equivalentes:

```bash
# Lista los skills del repo y deja elegir
npx skills add javalenciacai/siigo-pyme-excel-skill

# Instala apuntando directo a la ruta del skill
npx skills add https://github.com/javalenciacai/siigo-pyme-excel-skill/tree/main/skills/siigo-pyme-excel
```

El CLI copia el skill al directorio de skills de tu agente (Claude Code,
Cursor, Codex, etc.). Verifica con `npx skills list`.

### Instalación manual

Copia `skills/siigo-pyme-excel/` a la ruta de skills de tu agente
(p. ej. `~/.claude/skills/siigo-pyme-excel/`). Compatible con cualquier
agente que soporte skills con frontmatter YAML (`name` + `description`).

### Uso independiente (sin agente)

```bash
git clone https://github.com/javalenciacai/siigo-pyme-excel-skill.git
cd siigo-pyme-excel-skill/skills/siigo-pyme-excel
bash scripts/check-prereqs.sh
bash scripts/excel-siigo.sh list
```

## Prerrequisitos

Del sistema:

- **Windows** (el .exe es PE32 nativo). Wine experimental.
- **SIIGO Pyme** instalado, licenciado y con la empresa ya creada.
- **`EXCELSIIGO.exe`** accesible (por defecto `C:\Siigo\EXCELSIIGO.exe`).
- **`filepath.txt`** junto al .exe — lo crea SIIGO al instalar. Declara la
  ruta real de la empresa (suele ser `Z:\SIIWI0n\`, no `C:\SIIWI0n\`).
- **Usuario SIIGO** con permisos sobre la empresa (clave de 8 caracteres).
- **Licencia SIIGO** vigente (la valida el propio CLI).

Runtime:

- **Python 3.8+** con **openpyxl** — para `excel-siigo.py`, `parse-log.py`,
  `parse-filepath.py` y `build-xlsx-template.py`:
  ```bash
  pip install openpyxl
  pip install pandas    # opcional: post-proceso tabular de los .xlsx
  ```
- **PowerShell 5+** (sólo si usas el wrapper `.ps1`).
- **Bash** (sólo si usas el wrapper `.sh`).

### Variables de entorno

Los wrappers leen la configuración del entorno (o de flags equivalentes):

| Variable | Obligatoria | Descripción |
|---|---|---|
| `SIIGO_EXE` | sí | Ruta al `EXCELSIIGO.exe` |
| `SIIGO_EMPRESA` | sí | Ruta de la empresa, debe coincidir con `filepath.txt` |
| `SIIGO_USUARIO` | sí | Usuario SIIGO |
| `SIIGO_CLAVE` | sí | Clave de 8 caracteres |
| `SIIGO_LOGS` | no | Carpeta de logs (por defecto, la de `--salida`) |

```bash
export SIIGO_EXE='C:\Siigo\EXCELSIIGO.exe'
export SIIGO_EMPRESA='Z:\SIIWI01\'
export SIIGO_USUARIO='admin'
export SIIGO_CLAVE='12345678'
```

### Smoke test post-instalación

```bash
bash scripts/check-prereqs.sh      # valida .exe, filepath.txt, Python, openpyxl
bash scripts/excel-siigo.sh list   # lista las 46 funciones y la ruta detectada
```

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

## Estructura del repo

```
.
├── README.md
├── docs/                          # notas de diseño y publicación
└── skills/
    └── siigo-pyme-excel/          # el skill instalable
        ├── SKILL.md               # entry point (frontmatter name + description)
        ├── references/            # manual del CLI, catálogo, errores, encoding
        ├── scripts/               # wrappers .sh / .ps1 / .py y utilidades
        ├── assets/                # plantillas .xlsx generadas
        └── evals/                 # evals del skill
```

El layout `skills/<nombre>/SKILL.md` es el que escanea el CLI de skills.sh.
Ver [`docs/SKILLSH.md`](docs/SKILLSH.md).

## Documentación

- **[`skills/siigo-pyme-excel/SKILL.md`](skills/siigo-pyme-excel/SKILL.md)** — entry point del skill (léelo primero).
- **[`references/excel-siigo-help.md`](skills/siigo-pyme-excel/references/excel-siigo-help.md)** — manual oficial completo (961 líneas).
- **[`references/functions-catalog.md`](skills/siigo-pyme-excel/references/functions-catalog.md)** — las 46 funciones con sus params.
- **[`references/errors.md`](skills/siigo-pyme-excel/references/errors.md)** — códigos de error y recuperación.
- **[`references/encoding.md`](skills/siigo-pyme-excel/references/encoding.md)** — Windows-1252, rutas con espacios, Wine.
- **[`references/filepath-txt.md`](skills/siigo-pyme-excel/references/filepath-txt.md)** — formato de `filepath.txt`.
- **[`references/siigo-pyme-concepts.md`](skills/siigo-pyme-excel/references/siigo-pyme-concepts.md)** — glosario de términos SIIGO.
- **[`docs/SKILLSH.md`](docs/SKILLSH.md)** — publicación e indexación en skills.sh.
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
