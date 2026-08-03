---
name: siigo-pyme-excel
description: Use this skill whenever the user needs to extract data from SIIGO Pyme (Colombia) to Excel, or import Excel data into SIIGO Pyme, using the proprietary EXCELSIIGO.exe CLI. Also use when the user wants to filter, aggregate, merge, validate, or convert a previously generated SIIGO .xlsx (e.g. Terceros, GETMOV, GETBOD) without re-running the CLI. Triggers on requests like "sacar un listado de SIIGO", "cargar terceros a SIIGO", "generar movimientos contables desde un Excel", "descargar saldos de bodega", "importar productos a SIIGO Pyme", "ejecutar EXCELSIIGO.exe", "sincronizar SIIGO con otro sistema", "filtrar el último reporte de movimientos", "cruzar Terceros con el GETMOV", or any mention of the SIIGO Pyme on-premise Windows ERP and its Excel interface. Wraps the 46 GET*/PUSH* functions of EXCELSIIGO.exe with Bash/PowerShell/Python wrappers, JSON output, prereq validation, log parsing, xlsx template generation, plus downstream processing (openpyxl/pandas) for already-generated .xlsx files. Do NOT use for SIIGO Nube (API REST) or SIIGO Empresarial — only for SIIGO Pyme on Windows.
---

# siigo-pyme-excel

Skill para invocar el CLI `ExcelSIIGO.exe` que SIIGO S.A.S. distribuye con su
software contable **SIIGO Pyme** (Colombia). Permite automatizar la
importación y exportación de datos entre SIIGO Pyme (on-premise) y archivos
Excel sin que el modelo tenga que memorizar la sintaxis del CLI.

> **Plataforma soportada**: solo Windows (el CLI es PE32 nativo). En Linux
> o macOS se requiere Wine o ejecución remota por RDP/PSExec.
>
> **SIIGO Pyme ≠ SIIGO Nube**: este skill es para la versión escritorio
> con `EXCELSIIGO.exe`. Para SIIGO Nube (API REST) usar otro skill.

## 1. Prerrequisitos

Antes de invocar el skill verifica que existan:

1. **SIIGO Pyme instalado** y con la empresa creada.
2. **`EXCELSIIGO.exe`** accesible. Por defecto el wrapper lo busca en
   `C:\Siigo\EXCELSIIGO.exe`. Configurable vía `SIIGO_EXE`.
3. **`filepath.txt`** junto al `EXCELSIIGO.exe` (lo crea SIIGO al instalar).
   El wrapper lo lee automáticamente para validar que la empresa solicitada
   coincide con la ruta declarada. Ver `references/filepath-txt.md`.
   **Importante**: la ruta declarada suele ser `Z:\SIIWI0n\`, NO `C:\SIIWI0n\`.
   Usa `bash scripts/excel-siigo.sh list` para ver la ruta detectada.
4. **Usuario SIIGO con permisos** sobre la empresa (clave de 8 caracteres).
5. **Licencia SIIGO activa** (la verificación la hace internamente el CLI
   vía `Actualizador.exe` y `CtrlSIIGOLic.gnt`).
6. **Carpeta LOGS** escribible. Por defecto los logs van al mismo
   directorio que el archivo de salida (`--salida`); también puedes
   configurar `SIIGO_LOGS` o pasar `--logs` al wrapper.
7. **Espacio en disco** suficiente para los .xlsx generados.

Ejecuta primero el validador:

```bash
bash scripts/check-prereqs.sh
```

## 1.1 Validación de empresa contra filepath.txt

Antes de ejecutar **cualquier** GET/PUSH, el wrapper valida que la empresa
solicitada (`SIIGO_EMPRESA`) coincide con la ruta declarada en el
`filepath.txt` que acompaña al `EXCELSIIGO.exe`. Si no coincide, **la
ejecución se bloquea** con un mensaje claro indicando a qué empresa apunta
esa instalación, y recordando que `filepath.txt` solo referencia UNA
empresa — para encontrar otras hay que buscar en otras rutas
`SIIWI*` o en otras instalaciones de SIIGO.

Ejemplo de bloqueo (pides `Z:\SIIWI99\`, el `EXCELSIIGO.exe` apunta a `Z:\SIIWI01\`):

```
╔════════════════════════════════════════════════════════════════════╗
║  ADVERTENCIA: la empresa solicitada NO coincide con filepath.txt  ║
╚════════════════════════════════════════════════════════════════════╝

SIIGO_EMPRESA:  Z:\SIIWI99\

Empresa declarada en el filepath.txt de este EXCELSIIGO.exe:
  Esta instalación de EXCELSIIGO.exe apunta a:
    - id=01  ruta=Z:\SIIWI01\  unc=\\127.0.0.1\inmunotek

RECORDATORIO: filepath.txt NO lista todas las empresas — solo apunta
a UNA (la de esta instalación). Las demás pueden existir en otras
rutas SIIWI02, SIIWI03, ... o en otras unidades. Para descubrirlas:
  - Listar carpetas C:\SIIWInn\ (o Z:\SIIWInn\ si la unidad está montada)
  - Buscar otros EXCELSIIGO.exe: C:\Siigo2\, C:\Siigo3\, ...
  - Cada instalación tiene SU PROPIO filepath.txt apuntando a SU empresa
```

Si necesitas saltarte la validación (porque tu instalación tiene un layout
no estándar), pasa `--force`:

```bash
bash scripts/excel-siigo.sh getter --fini 0 --ffin 99999999 \
    --salida C:/temp/t.xlsx --force --yes
```

Inspeccionar el filepath.txt manualmente:

```bash
python scripts/parse-filepath.py --exe C:/Siigo/EXCELSIIGO.exe
```

Más detalles en `references/filepath-txt.md`.

## 2. Configuración

Variables de entorno reconocidas por los wrappers:

| Variable          | Default                  | Descripción                                          |
|-------------------|--------------------------|------------------------------------------------------|
| `SIIGO_EXE`       | `C:\Siigo\EXCELSIIGO.exe`| Ruta al binario.                                     |
| `SIIGO_EMPRESA`   | *(sin default)*          | **Debes configurarlo** usando `parse-filepath.py` o `bash excel-siigo.sh list` (muestra la ruta detectada del filepath.txt). Típicamente `Z:\SIIWI01\`, **NO** `C:\SIIWI01\`. |
| `SIIGO_USUARIO`   | —                        | Usuario SIIGO (8 chars). **Obligatorio**.            |
| `SIIGO_CLAVE`     | —                        | Clave del usuario. **Obligatorio. Nunca en logs.**   |
| `SIIGO_NORMA`     | `L`                      | `L` (Local) o `N` (NIIF).                            |
| `SIIGO_LOGS`      | *(sin default)*          | Carpeta para archivos .LOG. Si está vacía, los logs van al mismo directorio que `--salida` (o `--logs`/`--entrada` según la función). |
| `SIIGO_ANO`       | año actual               | Año de proceso (4 dígitos).                          |
| `SIIGO_LANG`      | `es`                     | Idioma mensajes (`es`/`en`).                         |

> ⚠️ **Seguridad**: nunca hardcodees `SIIGO_CLAVE` en scripts. El wrapper
> enmascara la clave en cualquier log que emita.

## 3. Uso rápido (comandos copy-paste)

Asume que estás en la raíz del skill y que `SIIGO_*` ya están exportadas.

### 3.1 Listar funciones disponibles

```bash
bash scripts/excel-siigo.sh list
```

### 3.2 Extraer (GET*) plantillas vacías (sólo encabezados)

Útil para conocer las columnas que SIIGO espera antes de un PUSH*:

```bash
bash scripts/excel-siigo.sh template GETTER
# Genera: assets/templates/GETTER_template.xlsx
```

### 3.3 Extraer movimiento contable de un periodo

```bash
bash scripts/excel-siigo.sh getmov \
    --fini 0501 --ffin 0531 \
    --tipo F --comp 001 002 \
    --nro 00000000001 99999999999 \
    --salida C:/SIIWI01/MovimientoContable.xlsx
```

### 3.4 Importar terceros a SIIGO

```bash
bash scripts/excel-siigo.sh pushter \
    --entrada C:/SIIWI01/Terceros.xlsx \
    --errores C:/SIIWI01/LOGS/ErrorTer.xlsx
```

> **Operación destructiva**: el wrapper pedirá confirmación interactiva
> salvo que pases `--yes`. Úsalo sólo cuando estés seguro.

### 3.5 Extraer saldos de bodega

```bash
bash scripts/excel-siigo.sh getbod \
    --prod 0010001000001 9999999999999 \
    --bodega 0001 9999 --mes 12 \
    --salida C:/SIIWI01/SaldosPorBodega.xlsx
```

### 3.6 Extraer informe (balance de comprobación por tercero)

```bash
bash scripts/excel-siigo.sh getinf \
    --tipo B --tercero 1 9999999999999 \
    --mes 03 12 \
    --salida C:/SIIWI01/BALANCEPORTERCEROS.xls
```

## 4. Catálogo rápido de funciones (las 12 más usadas)

| Función     | GET/PUSH | Módulo              | Params clave                              |
|-------------|----------|---------------------|-------------------------------------------|
| `GETMOV`    | GET      | Movimiento contable | fechas, comprobante, cuentas, productos   |
| `PUSHMOV`   | PUSH     | Movimiento contable | archivo entrada, modifica?, básica?       |
| `GETTER`    | GET      | Terceros            | rango, clasificación, fechas apertura     |
| `PUSHTER`   | PUSH     | Terceros            | archivo entrada, log errores              |
| `GETINV`    | GET      | Inventarios         | rango productos                           |
| `PUSHINV`   | PUSH     | Inventarios         | archivo entrada, log errores              |
| `GETCTA`    | GET      | Contabilidad        | rango cuentas (10 dígitos)                |
| `GETACT`    | GET      | Activos fijos       | rango activos (9 dígitos)                 |
| `PUSHACT`   | PUSH     | Activos fijos       | archivo entrada, log errores              |
| `GETSAL`    | GET      | Cartera             | CxC/CxP, rango terceros y cuentas         |
| `GETBOD`    | GET      | Bodegas             | productos, bodegas, mes corte             |
| `GETINF`    | GET      | Informes            | tipo (`B`/`BCC`), rango terceros/cuentas  |

Catálogo completo (46 funciones) en `references/functions-catalog.md`.

## 5. Forma del resultado (contrato JSON)

Todos los wrappers imprimen en stdout un JSON con esta forma:

```json
{
  "ok": true,
  "exit_code": 0,
  "funcion": "GETMOV",
  "log_path": "C:\\SIIWI01\\LOGS\\ExcelSiigo.log",
  "log_lines": 42,
  "log_errors": [],
  "duration_ms": 1823,
  "output_file": "C:\\SIIWI01\\MovimientoContable.xlsx",
  "tail": "..."
}
```

En caso de error:

```json
{
  "ok": false,
  "exit_code": 2,
  "funcion": "GETMOV",
  "log_path": "C:\\SIIWI01\\LOGS\\ExcelSiigo.log",
  "log_errors": ["070 Empresa no se encuentra instalada"],
  "duration_ms": 412,
  "tail": "070 Empresa no se encuentra instalada"
}
```

## 6. Errores típicos (resumen)

| Código/Patrón | Significado                                       | Solución                                              |
|---------------|---------------------------------------------------|-------------------------------------------------------|
| `070`         | Empresa no instalada en la ruta                  | Verificar `SIIGO_EMPRESA` apunta a empresa válida     |
| `Acceso denegado` | Permisos insuficientes                        | Ejecutar como usuario con permisos sobre la empresa   |
| `Archivo no encontrado` | Ruta de entrada .xlsx inexistente     | Verificar `--entrada` o `--salida`                    |
| `Licencia vencida` | Licencia SIIGO caducada                      | Renovar licencia; correr `Actualizador.exe`           |
| Salida vacía o .xlsx corrupto | Proceso cortado a media ejecución | Revisar el .LOG; liberar memoria; reintentar          |

Tabla completa y procedimientos de recuperación en `references/errors.md`.

## 7. Seguridad y confirmación de operaciones destructivas

Cualquier función `PUSH*` (importa datos al SIIGO):

- **Modifica la base de la empresa**.
- Por defecto el wrapper **pide confirmación interactiva** (`--yes` para
  saltarla).
- Si la variable de entorno `SIIGO_AUTO_CONFIRM=1` está activa, salta la
  confirmación (útil para pipelines CI/CD; no recomendado en producción).
- El .LOG se conserva siempre y se puede auditar con `parse-log.py`.

## 8. Codificación y rutas con caracteres especiales

- El manual oficial (`C:\Siigo\ExcelSIIGO-Ayuda.LOG`) está en **Windows-1252**.
  Los acentos aparecen como `A�o`, `Funci�n`, etc. El skill normaliza todo
  a UTF-8.
- Las rutas con espacios o tildes (ej. `C:\Mi Empresa 2025\`) deben
  pasarse **siempre entre comillas dobles** en Bash. El wrapper lo hace
  automáticamente.

Más detalles en `references/encoding.md`.

## 9.1 Limitación: `EXCELSIIGO.exe` es un binario GUI

`EXCELSIIGO.exe` es un ejecutable **GUI de Windows** (PE32 GUI, no consola).
Eso significa que:

- ✅ Funciona correctamente en **sesiones Windows interactivas** (CMD,
  PowerShell, doble-clic, RDP).
- ✅ Funciona en **tareas programadas** que corren bajo la cuenta del
  usuario con sesión abierta.
- ❌ **NO funciona en shells headless** (CI/CD sin display, SSH puro,
  WSL sin X server, sesiones de chat remotas) — el binario muere
  silenciosamente al intentar inicializar la GUI: `rc=0`, sin log, sin
  XLSX de salida.
- ❌ **NO funciona con `nohup` o detached** sin un display server.

Síntomas típicos del problema:

- `excel-siigo.sh` devuelve `ok: true, exit_code: 0` pero no se genera
  ni el .log ni el .xlsx de salida.
- El archivo .log queda en 0 bytes.
- El .xlsx nunca aparece en la ruta solicitada.

**Diagnóstico**:

```bash
file "C:/Siigo/EXCELSIIGO.exe"
# Debe decir: PE32 executable for MS Windows ... (GUI), Intel i386
# Si dice (console) en vez de (GUI), esta limitación no aplica.
```

**Workaround** (cuando se necesita automatización real): lanzar el
comando desde una **tarea programada de Windows** que corra bajo
`SYSTEM` o el usuario con escritorio, y consumir el .xlsx resultante.
NO es viable automatizar `EXCELSIIGO.exe` desde shells sin GUI.

Si el agente que invoca el skill está en un shell headless, debe
advertir al usuario que el comando fallará silenciosamente y sugerirle
ejecutarlo en su propia sesión Windows.

## 9. Cuándo NO usar este skill

- **SIIGO Nube** (API REST). Usar el conector HTTP correspondiente.
- **SIIGO Empresarial** (versión enterprise). El CLI es distinto; este
  skill está orientado a Pyme.
- **Lectura directa de la base de datos SIIGO** (Access/SQL Anywhere). El
  CLI es la vía soportada.
- **macOS/Linux sin Wine**. No soportado oficialmente.
- **Shells headless o automatizaciones sin sesión interactiva** (CI, WSL
  sin X server, sesiones SSH puras, este chat). Ver §9.1 abajo.

## 10. Mantenimiento

Cuando SIIGO publique una nueva versión de `EXCELSIIGO.exe`:

1. Ejecuta `EXCELSIIGO.exe` sin empresa → captura el manual actualizado.
2. Sustituye `references/excel-siigo-help.md` con la nueva versión.
3. Actualiza `references/functions-catalog.md` si hay funciones nuevas o
   params que cambiaron.
4. Compara con `git diff` antes de commitear.
5. Taggea nueva versión (`v0.2.0`, etc.).

## 11. Estructura del repositorio

```
siigo-pyme-excel/
├── SKILL.md
├── README.md
├── LICENSE
├── references/        # docs cargables bajo demanda
├── scripts/           # wrappers ejecutables
├── assets/templates/  # plantillas .xlsx generadas dinámicamente
└── docs/              # SDD y notas de diseño
```

## 12. Referencias internas

- `references/excel-siigo-help.md` — copia completa del manual oficial.
- `references/functions-catalog.md` — las 46 funciones documentadas.
- `references/errors.md` — códigos de error y recuperación.
- `references/encoding.md` — Windows-1252, comillas, rutas largas.
- `references/siigo-pyme-concepts.md` — glosario de términos SIIGO.
- `references/filepath-txt.md` — cómo el CLI localiza la empresa (filepath.txt).
- `docs/SDD-EXPLORE.md` y `docs/SDD-PROPOSE.md` — diseño del skill.

## 13. Persistencia y reutilización de outputs

**Importante**: una vez generado un .xlsx por el CLI, el archivo es
completamente independiente de SIIGO. NO hace falta volver a ejecutar
el .exe para trabajar con los datos — se puede usar Excel, Python,
pandas, Power Query, etc. directamente sobre el archivo.

**Esta sección documenta cómo el agente (skill) y el usuario pueden
cooperar para que los .xlsx generados sean reutilizables entre
sesiones**, sin tener que regenerarlos cada vez.

### 13.1 Carpeta persistente recomendada

El wrapper por defecto escribe el .xlsx en la ruta que el usuario pasa
con `--salida`. Si esa ruta es temporal (`C:\\temp\\...` o similar), el
archivo se puede perder al reiniciar el sistema o limpiar Temp.

**Recomendación**: usar una carpeta dedicada para outputs SIIGO, por
ejemplo:

```
C:\SIIGO_Reportes\             # raíz
├── empresa_01\
│   ├── 2026\
│   │   ├── 01_enero\
│   │   ├── 02_febrero\       # ej. Movimiento_2026_ene_feb.xlsx
│   │   ├── ...
│   │   └── 12_diciembre\
│   ├── Terceros\             # ej. Terceros_empresa1.xlsx
│   ├── Saldos\
│   └── Inventarios\
└── empresa_02\
    └── ...
```

Convención recomendada: `<empresa>/<año>/<mes_o_categoría>/`. Esto:

- Permite versionar (un .xlsx por mes no se sobreescribe).
- Facilita referencias cruzadas entre reportes (un GETMOV de enero
  tiene relación con un GETTER de enero).
- Hace fácil automatizar mesclas (`merge` entre meses para acumulado
  anual, `vlookup` contra Terceros para enriquecer con NIT/dirección).

### 13.2 Comportamiento del agente con archivos generados

Después de generar un .xlsx, el agente debe:

1. **Registrar el archivo en su memoria de trabajo** de la sesión actual.
   Si el agente tiene `memory` o `session_search`, guardar:
   - Ruta absoluta del .xlsx
   - Función SIIGO usada (GETMOV, GETTER, etc.)
   - Rango de fechas / filtros aplicados
   - Timestamp de generación
   - Tamaño y número de filas/columnas

2. **NO regenerarlo en futuras sesiones** a menos que el usuario lo pida.
   Si el usuario pide "el listado de terceros que generaste ayer",
   el agente debe:
   - Buscar primero si el archivo ya existe en la carpeta persistente.
   - Si existe y la fecha es razonable, leerlo directamente con
     `openpyxl` y responder con datos del archivo.
   - Solo regenerar si el archivo no existe, está obsoleto, o el
     usuario lo pide explícitamente.

3. **Sugerir la carpeta persistente** la primera vez que el usuario
   genera un archivo, si no la ha configurado. Ejemplo de respuesta:

   ```
   Generé C:\temp\Terceros_2026.xlsx con 982 terceros.
   
   ⚠️ Esta carpeta es temporal. ¿Quieres que la mueva a una carpeta
   persistente como C:\SIIGO_Reportes\empresa_01\Terceros\?
   Si me dices "sí", puedo:
   - Mover el archivo a la nueva ubicación
   - Recordar esa ruta para futuras sesiones
   - Hacer backups automáticos antes de regenerar
   ```

### 13.3 Procesamiento posterior (el caso de uso común)

Una vez generado un .xlsx, el caso de uso más frecuente es
**procesarlo sin tocar SIIGO**. Esto puede ser:

- **Filtrar**: por cuenta, tercero, fecha, tipo doc, valor, etc.
- **Agregar**: totales por mes, por cuenta, por tercero.
- **Mesclar**: con otros .xlsx generados (ej. Terceros + GETMOV para
  enriquecer con NIT/dirección/ciudad).
- **Validar**: contra PUC, contra saldos esperados, contra presupuesto.
- **Convertir**: a CSV/JSON/SQL para importar a otro sistema.

**El agente DEBE ofrecerse主动 a hacer esto** cuando el usuario
genera un .xlsx. Frases disparadoras en la respuesta:

- "¿Quieres que filtre/limpie/agregue/mescle esto con...?"
- "¿A qué carpeta quieres moverlo para no perderlo?"
- "¿Quieres que te genere un reporte derivado (ej. balance por
  tercero, total por cuenta, top 10 proveedores)?"

### 13.4 Convención de nombres sugerida

Para que el agente y el usuario se entiendan al referirse a archivos:

```
<funcion>_<empresa>_<periodo>_<fecha_generacion>.xlsx
```

Ejemplos:
- `GETMOV_empresa01_2026-01-01_2026-02-29_20260803.xlsx`
- `GETTER_empresa01_full_20260803.xlsx`
- `GETSAL_empresa01_2026-Q1_20260803.xlsx`
- `GETBOD_empresa01_2026-12_20260803.xlsx`

El wrapper NO fuerza esta convención (el usuario elige `--salida`), pero
es útil para reportes automáticos y para que el agente pueda inferir
qué archivos son "viejos" o "ya generados".

### 13.5 Tabla de outputs por sesión (memoria del agente)

Si el agente tiene acceso a memoria persistente o a una nota de sesión,
recomendarle guardar una tabla como:

| Archivo | Función | Período | Filas | Generado | Carpeta |
|---------|---------|---------|-------|----------|---------|
| `GETTER_empresa01_full.xlsx` | GETTER | todos | 982 | 2026-08-03 | `C:\SIIGO_Reportes\empresa_01\Terceros\` |
| `GETMOV_empresa01_2026-ene-feb.xlsx` | GETMOV | 2026-01-01 a 2026-02-29 | 5898 | 2026-08-03 | `C:\SIIGO_Reportes\empresa_01\2026\02_febrero\` |

Esto evita regenerar archivos y permite al agente cruzar información
entre reportes.
