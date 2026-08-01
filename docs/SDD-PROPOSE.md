# SDD Propose — Skill `siigo-pyme-excel`

## 1. Nombre del skill

**`siigo-pyme-excel`**

## 2. Propósito

Permitir que un agente (Hermes, Claude, Pi, etc.) **automatice el intercambio
de datos entre SIIGO Pyme y archivos Excel** mediante el CLI
`ExcelSIIGO.exe`, sin que el modelo tenga que memorizar la sintaxis ni los
rangos válidos de cada función.

El skill NO reemplaza al usuario: el usuario sigue siendo quien decide qué
empresa, año, norma, usuario y clave usar; el skill es el **puente seguro y
trazable** entre la IA y el CLI.

## 3. Audiencia

- Contadores, auxiliares contables y consultores SIIGO en Colombia.
- Equipos de TI que mantienen integraciones entre SIIGO Pyme (on-prem) y
  sistemas externos (BI, ERPs, CRM, e-commerce, software propio como Reportia).
- Otros agentes IA que necesiten datos de SIIGO Pyme sin un driver ODBC.

## 4. Estructura del skill

```
siigo-pyme-excel/
├── SKILL.md                       # entry point (≤ 200 líneas ideal)
├── README.md                      # repo, instalación, ejemplos
├── LICENSE                        # MIT
├── references/
│   ├── excel-siigo-help.md        # copia del manual oficial (C:\Siigo\ExcelSIIGO-Ayuda.LOG normalizado a UTF-8)
│   ├── functions-catalog.md       # tabla de las 46 funciones con sus params
│   ├── encoding.md                # notas sobre Windows-1252, rutas con espacios
│   ├── errors.md                  # tabla de errores conocidos (070, etc.)
│   └── siigo-pyme-concepts.md     # términos: comprobante, tercero, cuenta, etc.
├── scripts/
│   ├── excel-siigo.sh             # wrapper Bash (MSYS / Git Bash / WSL)
│   ├── excel-siigo.ps1            # wrapper PowerShell (Windows nativo)
│   ├── excel-siigo.py             # wrapper Python multiplataforma
│   ├── parse-log.py               # parsea el .LOG de salida a JSON
│   ├── check-prereqs.sh           # valida ExcelSIIGO.exe + empresa + licencia
│   └── build-xlsx-template.py     # genera .xlsx con encabezados a partir de ConDatos=N
├── assets/
│   └── templates/                 # (opcional) plantillas .xlsx precargadas
└── docs/
    ├── SDD-EXPLORE.md
    └── SDD-PROPOSE.md
```

## 5. Diseño de SKILL.md

Frontmatter YAML mínimo:

```yaml
---
name: siigo-pyme-excel
description: Automatiza ExcelSIIGO.exe (CLI de SIIGO Pyme) para extraer (GET*) e importar (PUSH*) datos entre SIIGO Pyme y archivos Excel (.xlsx). Usar cuando el usuario pida generar movimientos, cargar terceros/productos/cuentas, descargar saldos de bodega/cartera, informes contables, o sincronizar SIIGO Pyme con otro sistema.
---
```

Cuerpo (sin volcar la doc entera, sólo lo accionable):

1. **Prerrequisitos**: Windows + SIIGO Pyme instalado + ExcelSIIGO.exe
   accesible + empresa creada + usuario con permisos + licencia activa.
2. **Configuración**: variables de entorno (`SIIGO_EXE`, `SIIGO_EMPRESA`,
   `SIIGO_USUARIO`, `SIIGO_CLAVE`, `SIIGO_NORMA`, `SIIGO_LOGS`). Nunca
   hardcodear claves en scripts; preferir variables.
3. **Comandos típicos** (5-10 ejemplos copy-paste):
   - Listar funciones (consultar el .LOG).
   - Extraer movimiento de mayo: `excel-siigo GETMOV ...`.
   - Importar terceros: `excel-siigo PUSHTER ...`.
   - Extraer saldos de bodega.
4. **Mapeo función → params**: tabla corta (no las 46, sólo las 6-8 más
   comunes). El resto se referencia a `references/functions-catalog.md`.
5. **Cómo invocar el wrapper** (`./scripts/excel-siigo.sh <funcion> ...`).
6. **Cómo parsear el resultado** (código de salida + .LOG).
7. **Destructivos**: cualquier PUSH* requiere confirmación. Marcar en la
   descripción del script `confirm: true` si el runtime lo soporta.
8. **Errores típicos y cómo resolverlos** (resumen; tabla completa en
   `references/errors.md`).
9. **Cuándo NO usar este skill** (SIIGO Nube / SIIGO API REST, otros ERPs).
10. **Cómo mantener actualizado el skill** cuando SIIGO publique nuevas
    versiones de ExcelSIIGO.exe.

## 6. Wrappers propuestos

### `scripts/excel-siigo.sh` (Bash / MSYS)

- Recibe `Funcion` y los params posicionales.
- Construye el comando completo invocando `EXCELSIIGO.exe`.
- Captura stdout/stderr, exit code, y el archivo .LOG.
- Imprime JSON con `{ ok, exit_code, log_path, duration_ms, tail_log }` para
  que el agente lo consuma fácil.
- Para funciones PUSH* lee stdin o variable de entorno `CONFIRM=yes` antes
  de ejecutar.

### `scripts/excel-siigo.ps1` (PowerShell)

Equivalente nativo Windows, mismo contrato JSON. Necesario porque el bash
de git-for-windows maneja mal algunos argumentos con espacios y acentos.

### `scripts/excel-siigo.py` (Python, fallback)

Pensado para integraciones desde otros scripts Python. Importable como
módulo: `from excel_siigo import run(funcion, ...)`. Útil para Reportia.

### `scripts/parse-log.py`

Dado un .LOG, devuelve JSON con:
- `ok: bool` (true si el log no contiene "ERROR" ni "070").
- `lines: int`.
- `errors: [string]`.
- `summary: string` (últimas 20 líneas relevantes).

### `scripts/check-prereqs.sh`

- Verifica que `ExcelSIIGO.exe` existe.
- Verifica que la empresa existe (`ls C:\SIIWI01\` por defecto, configurable).
- Verifica permisos de lectura/escritura sobre la carpeta LOGS.
- Verifica que no haya otro ExcelSIIGO.exe corriendo (`tasklist` en Windows).
- Sale con código 0 si todo OK, 1 con detalle si falta algo.

### `scripts/build-xlsx-template.py`

Recibe `Funcion` y opcionalmente `Salida`. Llama al wrapper con `ConDatos=N`
para que ExcelSIIGO genere el .xlsx con sólo los encabezados, y lo deja en
`assets/templates/<funcion>_template.xlsx`. Útil para que el usuario sepa
exactamente qué columnas llenar antes de un PUSH*.

## 7. Seguridad y secretos

- **Nunca** guardar `SIIGO_CLAVE` en el repo. El wrapper lo lee de variable
  de entorno o de un `.env` local ignorado por .gitignore.
- Por defecto el wrapper **muestra la clave enmascarada** en logs
  (`Clave: ******`).
- El skill NO debe ejecutarse contra SIIGO Pyme de producción sin
  confirmación explícita del usuario (marca `confirm: true` en PUSH*).
- El .LOG generado puede contener datos sensibles (NIT, nombres). El skill
  advierte al usuario de proteger la carpeta LOGS.

## 8. Pruebas (acceptance criteria)

| #  | Criterio                                                                 | Cómo se verifica                                              |
|----|--------------------------------------------------------------------------|---------------------------------------------------------------|
| 1  | `excel-siigo.sh --help` imprime ayuda clara                              | `bash scripts/excel-siigo.sh --help`                          |
| 2  | `excel-siigo.sh list` lista las 46 funciones del manual                 | diff contra `references/functions-catalog.md`                 |
| 3  | Llamada a una función inexistente devuelve `ok=false` sin crashear       | `bash scripts/excel-siigo.sh NOTAFUN ...`                     |
| 4  | Empresa no instalada produce error `070` parseado a JSON                | ejecutar contra `C:\NOEXISTE\` (mock)                         |
| 5  | `check-prereqs.sh` detecta ausencia de `ExcelSIIGO.exe`                  | ejecutar sin SIIGO instalado (mock)                           |
| 6  | `parse-log.py` extrae errores del .LOG real                              | correr contra un .LOG generado con `ConDatos=N`               |
| 7  | SKILL.md carga en skills.sh (formato frontmatter válido)                 | `python -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"` |
| 8  | Repo público en GitHub con README y LICENSE                              | `gh repo view --json visibility,name`                         |

## 9. Publicación

1. Repo público en GitHub: `https://github.com/<usuario>/siigo-pyme-excel-skill`.
2. README bilingüe (es/en) con instalación, ejemplos y referencia rápida.
3. LICENSE MIT.
4. Registrar el repo en **skills.sh** siguiendo el flujo de esa plataforma
   (instrucciones en `docs/SKILLSH.md`).
5. Tag inicial `v0.1.0`.

## 10. Roadmap post-v1

- Wrapper Node.js para integraciones JS/TS.
- Generador interactivo de comandos (CLI TUI).
- Soporte para Wine en Linux/macOS (experimental).
- Plantillas .xlsx prellenas para casos típicos (carga inicial, cierre mensual).
- Tests con un mock de `ExcelSIIGO.exe` que simule el contrato.

## 11. Decisiones pendientes para el usuario

- **Nombre del repo en GitHub**: ¿`siigo-pyme-excel-skill` u otro?
- **Cuenta de GitHub** para publicar (la que esté activa en `gh`).
- **Idioma principal del skill**: español (default propuesto) o bilingüe.
