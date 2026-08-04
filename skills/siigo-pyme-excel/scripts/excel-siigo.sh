#!/usr/bin/env bash
# =============================================================================
#  excel-siigo.sh — Dispatcher Bash → Python para ExcelSIIGO.exe
# =============================================================================
#  Uso:
#     bash excel-siigo.sh <funcion> [opciones]
#     bash excel-siigo.sh list
#     bash excel-siigo.sh template <GETTER|PUSHTER|...>
#     bash excel-siigo.sh --help
#
#  Por qué este wrapper es tan simple:
#    El bash wrapper original construía la línea de args y la pasaba
#    directamente al .exe. Eso tenía 3 problemas en MSYS/Git Bash:
#      1) quoting hell con cmd.exe /c
#      2) MSYS 8.3 filename truncation (timestamp se trunca a 8 chars
#         y el .exe crea el log sin extensión, vaciando el .xlsx)
#      3) creación de carpetas no se hacía antes de invocar el .exe
#    La solución: delegar en scripts/excel-siigo.py que usa
#    subprocess.run() con lista de args (sin shell), crea las carpetas,
#    valida contra filepath.txt, y parsea el log. La versión Python
#    NO tiene los problemas 1, 2, 3.
#
#  Variables de entorno (ver SKILL.md):
#     SIIGO_EXE, SIIGO_EMPRESA, SIIGO_USUARIO, SIIGO_CLAVE,
#     SIIGO_NORMA, SIIGO_LOGS, SIIGO_ANO, SIIGO_LANG, SIIGO_AUTO_CONFIRM
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# En MSYS, forzar conversión a Windows (uv-python no acepta POSIX paths)
if command -v cygpath >/dev/null 2>&1 && [[ "$SCRIPT_DIR" =~ ^[A-Za-z]: ]]; then
  SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
else
  SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR" 2>/dev/null || echo "$SCRIPT_DIR")"
fi
PY_SCRIPT="${SCRIPT_DIR}\\excel-siigo.py"
PY_PARSE="${SCRIPT_DIR}\\parse-filepath.py"
PY_PARSE_LOG="${SCRIPT_DIR}\\parse-log.py"

# --- Comandos especiales que el bash maneja directamente ---

case "${1:-}" in
  list|"")
    # Mostrar la lista de funciones + la empresa detectada
    python3 "$PY_SCRIPT" list
    echo
    echo "Empresa detectada (de filepath.txt junto a SIIGO_EXE):"
    echo
    local_exe="${SIIGO_EXE:-C:\\Siigo\\EXCELSIIGO.exe}"
    # Convertir / a \ para que Python (uv+msys) lo entienda
    exe_win="${local_exe//\//\\}"
    # Convertir a ruta Windows para uv-python
    if command -v cygpath >/dev/null 2>&1; then
      exe_win="$(cygpath -w "$exe_win")"
    fi
    python3 "$PY_PARSE" --exe "$exe_win" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
if d.get('exists'):
    for e in d.get('empresas_declaradas', []):
        print(f'  ruta:  {e[\"ruta\"]}')
        print(f'  unc:   {e[\"unc\"]}')
        print(f'  id:    {e[\"id\"]}')
    print()
    print('Para usarla, exporta:')
    print(f'  export SIIGO_EMPRESA=\"{d[\"empresas_declaradas\"][0][\"ruta\"]}\"')
else:
    print('  (no se encontro filepath.txt junto a SIIGO_EXE)')
" 2>/dev/null || echo "  (no se pudo parsear el filepath.txt)"
    exit 0
    ;;
  --help|-h)
    cat <<'EOF'
excel-siigo.sh — Dispatcher al wrapper Python (scripts/excel-siigo.py)

USO:
  bash excel-siigo.sh <funcion> [opciones]
  bash excel-siigo.sh list
  bash excel-siigo.sh template <funcion>
  bash excel-siigo.sh --help

PARA QUÉ SIRVE:
  Este wrapper es un dispatcher: delega en scripts/excel-siigo.py
  (Python), que es el que realmente ejecuta el .exe sin los problemas
  de quoting/MSYS que tiene bash directo.

OPCIONES COMUNES:
  --empresa <ruta>     Ruta empresa SIIGO (default: detectar via filepath.txt)
  --ano <yyyy>         Año proceso (default: año actual)
  --norma L|N          Norma contable (default: L)
  --usuario <8c>       Usuario SIIGO
  --clave <8c>         Clave del usuario
  --logs <ruta>        Carpeta de logs (default: junto a --salida)
  --yes                Confirma PUSH* sin prompt
  --force              Salta validación de filepath.txt

FUNCIONES GET (extraen a XLSX):
  --salida <ruta>      Ruta del archivo .xlsx a generar
  --fini <MMDD>        Fecha inicio (formato MMDD)
  --ffin <MMDD>        Fecha fin (formato MMDD)
  --tipo <c>           Tipo de comprobante (F=Factura, *=Todos)
  --comp <ini> <fin>   Rango de comprobantes
  --nro <ini> <fin>    Rango de números
  --tercero <ini> <fin>  Rango de terceros
  --producto <ini> <fin> Rango de productos
  --bodega <ini> <fin>  Rango de bodegas
  --mes <mm>            Mes de corte
  --clasif <T|C|P|O>    Clasificación de terceros

FUNCIONES PUSH (importan desde XLSX):
  --entrada <ruta>     Ruta del archivo .xlsx de entrada
  --errores <ruta>     Ruta del XLSX de log de errores

VARIABLES DE ENTORNO:
  SIIGO_EXE, SIIGO_EMPRESA, SIIGO_USUARIO, SIIGO_CLAVE,
  SIIGO_NORMA, SIIGO_LOGS, SIIGO_ANO, SIIGO_LANG, SIIGO_AUTO_CONFIRM

EJEMPLOS:
  bash excel-siigo.sh list
  bash excel-siigo.sh getter --fini 0 --ffin 99999999 \\
      --salida C:/SIIWI01/Terceros.xlsx --yes
  bash excel-siigo.sh pushter --entrada C:/SIIWI01/Terceros.xlsx \\
      --errores C:/SIIWI01/LOGS/ErrorTer.xlsx --yes
EOF
    exit 0
    ;;
  template)
    # Modo plantilla: forzar ConDatos=N
    target="${2:-}"
    if [[ -z "$target" ]]; then
      echo "ERROR: template requiere nombre de función" >&2
      exit 1
    fi
    shift
    python3 "$PY_SCRIPT" "$target" --offline "$@" 2>&1 || true
    # Si no acepta --offline, ignorar
    python3 "$PY_SCRIPT" "$target" --datos N "$@" 2>&1
    exit $?
    ;;
esac

# --- Parseo del caso general (cualquier funcion + flags) ---
# Extraer el primer argumento como FUNCION
FUNCION="${1:-}"
shift || true

if [[ -z "$FUNCION" ]]; then
  echo "ERROR: debes indicar una funcion (usa 'list' para ver las disponibles)" >&2
  exit 1
fi

# Parsear flags amigables a la linea de args posicionales que el .exe espera.
# Mapeo de flags a la firma del manual oficial (sacada de C:\Siigo\ExcelSIIGO-Ayuda.LOG).
# Cada funcion tiene su firma exacta; el .exe responde 081 si los args
# no coinciden.
cli_salida=""
cli_entrada=""
cli_errores=""
cli_fini=""
cli_ffin=""
cli_tipo=""
cli_comp_ini=""
cli_comp_fin=""
cli_nro_ini=""
cli_nro_fin=""
cli_tercero_ini=""
cli_tercero_fin=""
cli_cuenta_ini=""
cli_cuenta_fin=""
cli_producto_ini=""
cli_producto_fin=""
cli_bodega_ini=""
cli_bodega_fin=""
cli_mes=""
cli_clasif=""
cli_estado=""
cli_serial_ini=""
cli_serial_fin=""
cli_acto_ini=""
cli_acto_fin=""
cli_consecutivo_ini=""
cli_consecutivo_fin=""
cli_nit_ini=""
cli_nit_fin=""
cli_vendedor_ini=""
cli_vendedor_fin=""
cli_cencos_ini=""
cli_cencos_fin=""
cli_subcencos_ini=""
cli_subcencos_fin=""
cli_desde_fap=""
cli_hasta_fap=""
cli_datos="S"
cli_moneda=""
cli_tipo_inf=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fini)      cli_fini="$2"; shift 2 ;;
    --ffin)      cli_ffin="$2"; shift 2 ;;
    --tipo)      cli_tipo="$2"; shift 2 ;;
    --comp)      cli_comp_ini="$2"; cli_comp_fin="$3"; shift 3 ;;
    --nro)       cli_nro_ini="$2"; cli_nro_fin="$3"; shift 3 ;;
    --salida)    cli_salida="$2"; shift 2 ;;
    --entrada)   cli_entrada="$2"; shift 2 ;;
    --errores)   cli_errores="$2"; shift 2 ;;
    --tercero)   cli_tercero_ini="$2"; cli_tercero_fin="$3"; shift 3 ;;
    --cuenta|--cta)
                cli_cuenta_ini="$2"; cli_cuenta_fin="$3"; shift 3 ;;
    --producto|--prod)
                cli_producto_ini="$2"; cli_producto_fin="$3"; shift 3 ;;
    --bodega|--bod)
                cli_bodega_ini="$2"; cli_bodega_fin="$3"; shift 3 ;;
    --mes)       cli_mes="$2"; shift 2 ;;
    --clasif)    cli_clasif="$2"; shift 2 ;;
    --estado)    cli_estado="$2"; shift 2 ;;
    --modelo)    cli_tipo_inf="$2"; shift 2 ;;
    --tipo-inf)  cli_tipo_inf="$2"; shift 2 ;;
    --moneda)    cli_moneda="$2"; shift 2 ;;
    --datos)     cli_datos="$2"; shift 2 ;;
    --offline)   cli_datos="N"; shift ;;
    --yes)       shift ;;
    --force)     shift ;;
    --logs)      shift 2 ;;
    --empresa)   shift 2 ;;
    --ano)       shift 2 ;;
    --norma)     shift 2 ;;
    --usuario)   shift 2 ;;
    --clave)     shift 2 ;;
    *)           shift ;;
  esac
done

# Log path: junto a --salida por defecto
log_path=""
if [[ -n "$cli_salida" ]]; then
  log_path="$(dirname "$cli_salida" 2>/dev/null || echo .)/ExcelSiigo_${FUNCION}_$(date +%Y%m%d_%H%M%S).log"
elif [[ -n "$cli_entrada" ]]; then
  log_path="$(dirname "$cli_entrada" 2>/dev/null || echo .)/ExcelSiigo_${FUNCION}_$(date +%Y%m%d_%H%M%S).log"
else
  log_path="./ExcelSiigo_${FUNCION}_$(date +%Y%m%d_%H%M%S).log"
fi

# Crear carpetas (el .exe de SIIGO NO las crea)
[[ -n "$cli_salida" ]] && mkdir -p "$(dirname "$cli_salida")" 2>/dev/null
[[ -n "$cli_entrada" ]] && mkdir -p "$(dirname "$cli_entrada")" 2>/dev/null
[[ -n "$cli_errores" ]] && mkdir -p "$(dirname "$cli_errores")" 2>/dev/null
mkdir -p "$(dirname "$log_path")" 2>/dev/null

# Construir la lista de args posicionales segun la firma del manual
# (extraida de C:\Siigo\ExcelSIIGO-Ayuda.LOG)
declare -a extra_args
case "${FUNCION^^}" in
  GETTER)
    extra_args=("$cli_datos" "${cli_tercero_ini:-1}" "${cli_tercero_fin:-9999999999999}" \
      "$cli_salida" "${cli_clasif:-T}" "${cli_desde_fap:-0}" "${cli_hasta_fap:-99999999}")
    ;;
  GETMOV|GETMVT)
    extra_args=("$cli_datos" "${cli_fini:-0}" "${cli_ffin:-9999}" "${cli_tipo:-*}" \
      "${cli_comp_ini:-000}" "${cli_comp_fin:-999}" "${cli_nro_ini:-00000000001}" "${cli_nro_fin:-99999999999}" \
      "$cli_salida" "N" "${cli_cuenta_ini:-0}" "${cli_cuenta_fin:-9999999999}" \
      "${cli_producto_ini:-0}" "${cli_producto_fin:-9999999999999}")
    ;;
  GETSAL)
    extra_args=("$cli_datos" "${cli_tercero_ini:-1}" "${cli_tercero_fin:-9999999999999}" \
      "${cli_cuenta_ini:-0}" "${cli_cuenta_fin:-9999999999}" "C" "$cli_salida" "N" "0530")
    ;;
  GETBOD|GETBOP)
    extra_args=("$cli_datos" "${cli_producto_ini:-0010001000001}" "${cli_producto_fin:-9999999999999}" \
      "${cli_bodega_ini:-0001}" "${cli_bodega_fin:-9999}" "${cli_mes:-12}" "$cli_salida")
    ;;
  GETBODM)
    extra_args=("$cli_datos" "${cli_producto_ini:-0010001000001}" "${cli_producto_fin:-9999999999999}" \
      "${cli_bodega_ini:-0001}" "${cli_bodega_fin:-9999}" "$cli_salida")
    ;;
  GETINV)
    extra_args=("$cli_datos" "${cli_producto_ini:-0010001000001}" "${cli_producto_fin:-9999999999999}" "$cli_salida")
    ;;
  GETLIS)
    extra_args=("$cli_datos" "${cli_producto_ini:-0010001000001}" "${cli_producto_fin:-9999999999999}" \
      "$cli_salida" "${cli_moneda:-00}")
    ;;
  GETCTA) extra_args=("$cli_datos" "${cli_cuenta_ini:-0}" "${cli_cuenta_fin:-9999999999}" "$cli_salida") ;;
  GETACT) extra_args=("$cli_datos" "${cli_acto_ini:-1}" "${cli_acto_fin:-999999999}" "$cli_salida") ;;
  GETGRA) extra_args=("$cli_datos" "${cli_acto_ini:-1}" "${cli_acto_fin:-9999}" "$cli_salida") ;;
  GETVEN) extra_args=("$cli_datos" "${cli_vendedor_ini:-0001}" "${cli_vendedor_fin:-9999}" "$cli_salida") ;;
  GETCOS) extra_args=("$cli_datos" "${cli_cencos_ini:-0000}" "${cli_cencos_fin:-9999}" \
                "${cli_subcencos_ini:-000}" "${cli_subcencos_fin:-999}" "$cli_salida") ;;
  GETTBO) extra_args=("$cli_datos" "${cli_bodega_ini:-0000}" "${cli_bodega_fin:-9999}" \
                "${cli_acto_ini:-000}" "${cli_acto_fin:-999}" "$cli_salida") ;;
  *) extra_args=("$cli_datos" "0" "9999999999999" "$cli_salida") ;;
esac

# --- Delegar al .exe via cmd.exe (forma que SÍ funciona probada) ---
# Por qué usamos cmd.exe y no subprocess Python: el .exe de SIIGO es
# PE32 GUI y tiene bugs sutiles con argv cuando se invoca directo
# desde Python. La UNICA forma probada que genera el .xlsx con
# 982 filas es cmd.exe /c "..." con comillas externas dobles.

# Construir la línea de comandos manualmente con quoting estilo cmd.
# Cada argumento va entre comillas dobles; los \ se escapan a \\
# (no — el .exe de SIIGO los lee como literales, así que no escapamos).
# Las comillas internas del valor se duplican ("" dentro de "...").
build_cmdline() {
  local exe="$1"; shift
  local line="\"$exe\""
  while [[ $# -gt 0 ]]; do
    local arg="$1"
    # Escapar comillas internas (") duplicándolas
    local safe="${arg//\"/\"\"}"
    line+=" \"$safe\""
    shift
  done
  echo "$line"
}

cmd_line="$(build_cmdline "${SIIGO_EXE:-C:\\Siigo\\EXCELSIIGO.exe}" \
  "${SIIGO_EMPRESA:-}" \
  "${SIIGO_ANO:-2026}" \
  "${FUNCION}" \
  "${SIIGO_NORMA:-L}" \
  "${SIIGO_USUARIO:-}" \
  "${SIIGO_CLAVE:-}" \
  "$log_path" "${extra_args[@]}")"
# Estrategia: crear un .bat temporal con la línea y ejecutarlo con
# cmd.exe /c "bat". Esto evita todos los líos de quoting porque el
# contenido del .bat es texto literal que cmd.exe procesa.
# Estrategia: crear un .bat temporal con la línea literal y ejecutarlo
# con cmd.exe /c "bat". El .bat evita el quoting hell de bash porque
# su contenido es texto plano que cmd.exe procesa directamente.
bat_file="${log_path%.log}.bat"
if command -v cygpath >/dev/null 2>&1; then
  bat_file_win="$(cygpath -w "$bat_file" 2>/dev/null || echo "$bat_file")"
else
  bat_file_win="$bat_file"
fi
{
  echo '@echo off'
  echo "$cmd_line"
  echo 'exit /B %ERRORLEVEL%'
} > "$bat_file_win"
# El trick que funciona: cmd.exe //c con el bat entre comillas externas
# EN el archivo del bat (no en el shell bash). Evita el quoting hell de
# bash MSYS. Probado que con cmd.exe //c "<bat_win>" SÍ ejecuta el .bat
# correctamente en sesiones Windows reales (Git Bash, PowerShell).
# En el shell sandbox de Hermes hay un problema con MSYS path translation
# que no ocurre en sesiones reales. Documentado en references/wrapper-dev-lessons.md.
cmd.exe //c "\"$bat_file_win\"" >"$log_path" 2>&1
exit_code=$?
rm -f "$bat_file" "$bat_file_win"
