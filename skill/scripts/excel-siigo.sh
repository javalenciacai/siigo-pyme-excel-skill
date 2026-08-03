#!/usr/bin/env bash
# =============================================================================
#  excel-siigo.sh — Wrapper Bash para ExcelSIIGO.exe (SIIGO Pyme)
# =============================================================================
#  Uso:
#     bash excel-siigo.sh <funcion> [opciones]
#     bash excel-siigo.sh list
#     bash excel-siigo.sh template <GETTER|PUSHTER|...>
#     bash excel-siigo.sh --help
#
#  Variables de entorno (opcional, ver SKILL.md):
#     SIIGO_EXE, SIIGO_EMPRESA, SIIGO_USUARIO, SIIGO_CLAVE,
#     SIIGO_NORMA, SIIGO_LOGS, SIIGO_ANO, SIIGO_LANG, SIIGO_AUTO_CONFIRM
# =============================================================================

set -euo pipefail

# ----- Constantes y defaults -------------------------------------------------

# SCRIPT_DIR: ruta POSIX al directorio del script (compatible con python3)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# En MSYS, forzar conversión a POSIX por si pwd devuelve ruta Windows
if command -v cygpath >/dev/null 2>&1 && [[ "$SCRIPT_DIR" =~ ^[A-Za-z]: ]]; then
  SCRIPT_DIR="$(cygpath -u "$SCRIPT_DIR")"
fi
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SIIGO_EXE="${SIIGO_EXE:-C:\\Siigo\\EXCELSIIGO.exe}"
# SIIGO_EMPRESA NO tiene default seguro. Cada instalación apunta a una
# ruta distinta (típicamente Z:\\SIIWI01\\, no C:\\SIIWI01\\). Usa
# `parse-filepath.py --exe <SIIGO_EXE>` para descubrir la ruta correcta.
SIIGO_EMPRESA="${SIIGO_EMPRESA:-}"
SIIGO_USUARIO="${SIIGO_USUARIO:-}"
SIIGO_CLAVE="${SIIGO_CLAVE:-}"
SIIGO_NORMA="${SIIGO_NORMA:-L}"
# SIIGO_LOGS NO tiene default. Si no se exporta, el wrapper usa el mismo
# directorio que el archivo de salida (--salida), con un nombre tipo
# ExcelSiigo_<FUNCION>_<TIMESTAMP>.log. Si pasas --logs, sobrescribe.
SIIGO_LOGS="${SIIGO_LOGS:-}"
SIIGO_ANO="${SIIGO_ANO:-$(date +%Y)}"
# Variables compartidas entre parse_args y main (declaradas globales para
# que sobrevivan al return de parse_args)
FUNCION=""
EXTRA=()
LOGS_DIR=""
SIIGO_LANG="${SIIGO_LANG:-es}"
SIIGO_AUTO_CONFIRM="${SIIGO_AUTO_CONFIRM:-0}"

# Catálogo de funciones (subset usado para validación)
readonly -a GET_FUNCS=(
  GETMOV PUSHMOV GETMVT
  GETTER PUSHTER
  GETGRA PUSHGRA GETACT PUSHACT
  GETEXT PUSHEXT
  GETLIN PUSHLIN GETINV PUSHINV GETLIS PUSHLIS GETKIT PUSHKIT GETPRE PUSHPRE
  GETBOD GETBOP GETBODM PUSHBODM
  GETSAL
  GETCTA PUSHCTA GETMUL PUSHMUL GETICA PUSHICA
  GETCIU GETVEN PUSHVEN GETCOS PUSHCOS GETTBO PUSHTBO
  GETSRL GETMSRL GETBSRL
  GETHN GETEMPL PUSHEMPL GETNOV
  GETINF
)

# ----- Helpers ---------------------------------------------------------------

# Detectar si estamos en MSYS / Git Bash y convertir ruta Windows a POSIX
to_posix() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$p" 2>/dev/null || echo "$p"
  else
    echo "$p"
  fi
}

# Envolver en comillas si tiene espacios
quote() {
  local s="$1"
  if [[ "$s" =~ [[:space:]] ]]; then
    printf '"%s"' "$s"
  else
    printf '%s' "$s"
  fi
}

# Detectar funciones PUSH* (destructivas)
is_destructive() {
  case "$1" in
    PUSH*) return 0 ;;
    *)     return 1 ;;
  esac
}

# Imprimir ayuda
print_help() {
  cat <<'EOF'
excel-siigo.sh — Wrapper Bash para ExcelSIIGO.exe

USO:
  bash excel-siigo.sh <funcion> [opciones comunes + opciones de la funcion]
  bash excel-siigo.sh list
  bash excel-siigo.sh template <funcion>
  bash excel-siigo.sh --help

OPCIONES COMUNES:
  --empresa <ruta>     Ruta empresa SIIGO (default: $SIIGO_EMPRESA)
  --ano <yyyy>         Año proceso (default: año actual)
  --norma L|N          Norma contable (default: L)
  --usuario <8c>       Usuario SIIGO
  --clave <8c>         Clave del usuario (no se loguea)
  --logs <ruta>        Carpeta de logs
  --yes                Confirma PUSH* sin prompt

FUNCIONES GET (extraen a XLSX):
  --salida <ruta>      Ruta del archivo .xlsx a generar

FUNCIONES PUSH (importan desde XLSX):
  --entrada <ruta>     Ruta del archivo .xlsx de entrada
  --errores <ruta>     Ruta del XLSX de log de errores

FUNCIONES ESPECIALES:
  list                 Lista las 46 funciones soportadas
  template <funcion>   Genera .xlsx con sólo encabezados (ConDatos=N)

NOTA: Los nombres de función son case-insensitive (getmov = GETMOV).

VARIABLES DE ENTORNO:
  SIIGO_EXE, SIIGO_EMPRESA, SIIGO_USUARIO, SIIGO_CLAVE,
  SIIGO_NORMA, SIIGO_LOGS, SIIGO_ANO, SIIGO_AUTO_CONFIRM

EJEMPLOS:
  bash excel-siigo.sh list
  bash excel-siigo.sh template GETTER
  bash excel-siigo.sh getmov --fini 0501 --ffin 0531 --tipo F \\
      --comp 001 002 --nro 1 99999999999 \\
      --salida "C:/SIIWI01/Movimiento.xlsx"
  bash excel-siigo.sh pushter --entrada "C:/SIIWI01/Terceros.xlsx" \\
      --errores "C:/SIIWI01/LOGS/ErrorTer.xlsx" --yes
EOF
}

# Imprimir lista de funciones
print_list() {
  echo "Funciones disponibles (46):"
  for f in "${GET_FUNCS[@]}"; do
    local kind="GET"
    [[ "$f" == PUSH* ]] && kind="PUSH"
    printf "  %-12s  %s\n" "$f" "$kind"
  done
  echo
  echo "Empresa detectada (de filepath.txt junto a SIIGO_EXE):"
  echo
  local exe_win
  if command -v cygpath >/dev/null 2>&1; then
    exe_win="$(cygpath -w "$SIIGO_EXE" 2>/dev/null)"
  else
    exe_win="$SIIGO_EXE"
  fi
  local py_script
  if command -v cygpath >/dev/null 2>&1; then
    py_script="$(cygpath -w "${SCRIPT_DIR}/parse-filepath.py" 2>/dev/null)"
  else
    py_script="${SCRIPT_DIR}/parse-filepath.py"
  fi
  python3 "$py_script" --exe "$exe_win" 2>/dev/null | python3 -c "
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
}

# Verificar que el .exe existe
verify_exe() {
  local posix_path
  posix_path="$(to_posix "$SIIGO_EXE")"
  if [[ ! -f "$posix_path" ]]; then
    echo "ERROR: ExcelSIIGO.exe no encontrado en: $SIIGO_EXE" >&2
    echo "       Verifica SIIGO_EXE o pasa --empresa para que apunte a la carpeta correcta" >&2
    return 1
  fi
}

# Valida que la empresa solicitada (SIIGO_EMPRESA) está declarada en el
# filepath.txt que acompaña al EXCELSIIGO.exe. Si no, emite una advertencia
# bloqueante (a menos que se pase --force). Esto evita apuntar a una
# empresa inexistente y obtener un .xlsx vacío o un error 070 confuso.
validate_company() {
  # Si el flag --force está activo, saltar
  if [[ "${SIIGO_FORCE:-0}" == "1" ]]; then
    return 0
  fi

  local py_script py_log py_out
  if command -v cygpath >/dev/null 2>&1; then
    py_script="$(cygpath -w "${SCRIPT_DIR}/parse-filepath.py")"
  else
    py_script="${SCRIPT_DIR}/parse-filepath.py"
  fi

  # Llamar al parser y capturar el JSON
  if command -v cygpath >/dev/null 2>&1; then
    local exe_win; exe_win="$(cygpath -w "$SIIGO_EXE")"
  else
    local exe_win="$SIIGO_EXE"
  fi

  # Llamar al parser y guardar el JSON en un archivo temporal
  local py_out_file="$log_posix.validate"
  if command -v cygpath >/dev/null 2>&1; then
    local py_out_file_win; py_out_file_win="$(cygpath -w "$py_out_file")"
  else
    local py_out_file_win="$py_out_file"
  fi

  python3 "$py_script" --exe "$exe_win" --empresa "$SIIGO_EMPRESA" >"$py_out_file_win" 2>/dev/null
  if [[ ! -s "$py_out_file_win" ]]; then
    # Si falla el parser, no bloqueamos — sólo avisamos
    echo "ADVERTENCIA: no se pudo leer filepath.txt para validar la empresa. Continuando..." >&2
    return 0
  fi

  # Extraer match_found con python (en archivo para evitar problemas de escape)
  local match_status_file="$log_posix.match"
  if command -v cygpath >/dev/null 2>&1; then
    local match_status_file_win; match_status_file_win="$(cygpath -w "$match_status_file")"
  else
    local match_status_file_win="$match_status_file"
  fi
  python3 -c "
import json, sys
with open(r'$py_out_file_win', 'r', encoding='utf-8') as f:
    d = json.load(f)
print('YES' if d.get('empresa_match_found', False) else 'NO')
" > "$match_status_file_win" 2>/dev/null

  local match_found; match_found="$(cat "$match_status_file_win" 2>/dev/null | tr -d '\r\n ')"
  if [[ "$match_found" != "YES" ]]; then
    echo "" >&2
    echo "╔════════════════════════════════════════════════════════════════════╗" >&2
    echo "║  ADVERTENCIA: la empresa solicitada NO coincide con filepath.txt  ║" >&2
    echo "╚════════════════════════════════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "SIIGO_EMPRESA:  $SIIGO_EMPRESA" >&2
    echo "" >&2
    echo "Empresa declarada en el filepath.txt de este EXCELSIIGO.exe:" >&2

    # Imprimir la empresa declarada (es UNA sola, no un índice)
    # Usamos un script Python en disco para evitar problemas de escape
    # de la ruta Windows al pasarla como argumento.
    local list_script="$log_posix.list_script.py"
    local list_script_win
    if command -v cygpath >/dev/null 2>&1; then
      list_script_win="$(cygpath -w "$list_script")"
    else
      list_script_win="$list_script"
    fi
    {
      echo "import json, sys"
      echo "with open(sys.argv[1], 'r', encoding='utf-8') as f:"
      echo "    d = json.load(f)"
      echo "print('  Esta instalación de EXCELSIIGO.exe apunta a:')"
      echo "for e in d.get('empresas_declaradas', []):"
      echo "    print(f\"    - id={e['id']}  ruta={e['ruta']}  unc={e['unc']}\")"
    } > "$list_script_win"
    python3 "$list_script_win" "$py_out_file_win" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      echo "  (no se pudo parsear el filepath.txt)" >&2
    fi
    echo "" >&2
    echo "RECORDATORIO: filepath.txt NO lista todas las empresas — solo apunta" >&2
    echo "a UNA (la de esta instalación). Las demás pueden existir en otras" >&2
    echo "rutas SIIWI02, SIIWI03, ... o en otras unidades. Para descubrirlas:" >&2
    echo "  - Listar carpetas C:\\SIIWInn\\ (o Z:\\SIIWInn\\ si la unidad está montada)" >&2
    echo "  - Buscar otros EXCELSIIGO.exe: C:\\Siigo2\\, C:\\Siigo3\\, ..." >&2
    echo "  - Cada instalación tiene SU PROPIO filepath.txt apuntando a SU empresa" >&2
    echo "" >&2
    echo "Si la empresa '$(basename "$(echo "$SIIGO_EMPRESA" | tr -d '\\')")' existe en otra" >&2
    echo "instalación de SIIGO, cambia SIIGO_EXE y SIIGO_EMPRESA para apuntar ahí." >&2
    echo "" >&2
    echo "Para forzar la ejecución con esta configuración, pasa --force." >&2
    return 1
  fi
  return 0
}

# Construir comando base
build_base_cmd() {
  local args=()
  args+=("$(quote "$SIIGO_EXE")")
  args+=("$(quote "$SIIGO_EMPRESA")")
  args+=("$SIIGO_ANO")
  args+=("$1") # funcion
  args+=("$SIIGO_NORMA")
  args+=("$(quote "$SIIGO_USUARIO")")
  args+=("$(quote "$SIIGO_CLAVE")")
  printf '%s\n' "${args[@]}"
}

# Verificar y parsear argumentos
check_required() {
  if [[ -z "$SIIGO_USUARIO" || -z "$SIIGO_CLAVE" ]]; then
    echo "ERROR: SIIGO_USUARIO y SIIGO_CLAVE son obligatorios" >&2
    echo "       Expórtalas antes de invocar el wrapper." >&2
    return 1
  fi
}

# Ejecutar el binario, capturar log, devolver JSON
run_excel_siigo() {
  local funcion="$1"; shift
  local extra_args=("$@")

  verify_exe || return 1
  check_required || return 1

  # Determinar carpeta de logs. Prioridad:
  #   1) --logs pasado en extra_args (último --logs <ruta>)
  #   2) $SIIGO_LOGS exportado
  #   3) directorio del archivo de salida (--salida)
  #   4) ./ (cwd del wrapper)
  # Las rutas SIEMPRE se convierten a formato Windows (\\ en vez de /)
  # porque el .exe de SIIGO espera rutas estilo Win32.
  local logs_dir=""
  # Buscar --logs en extra_args (asumimos formato --logs <ruta>)
  local i=0
  while [[ $i -lt ${#extra_args[@]} ]]; do
    if [[ "${extra_args[$i]}" == "--logs" && $((i+1)) -lt ${#extra_args[@]} ]]; then
      logs_dir="${extra_args[$((i+1))]}"
      break
    fi
    i=$((i+1))
  done
  if [[ -z "$logs_dir" && -n "$SIIGO_LOGS" ]]; then
    logs_dir="$SIIGO_LOGS"
  fi
  if [[ -z "$logs_dir" ]]; then
    # Fallback: directorio del archivo de salida (asumimos --salida es
    # el primer argumento que parezca una ruta .xlsx).
    for arg in "${extra_args[@]}"; do
      if [[ "$arg" =~ \.(xlsx|xls)$ ]] || [[ "$arg" =~ ^[A-Za-z]:.*$ && "$arg" == *\\* ]]; then
        local arg_dir
        arg_dir="$(dirname "$arg" 2>/dev/null || echo "")"
        if [[ -n "$arg_dir" ]]; then
          # Convertir / a \ para que el .exe de SIIGO lo entienda
          logs_dir="${arg_dir//\//\\}"
          break
        fi
      fi
    done
  fi
  if [[ -z "$logs_dir" ]]; then
    logs_dir="."
  fi

  # Crear carpeta LOGS si no existe
  local logs_posix
  logs_posix="$(to_posix "$logs_dir")"
  mkdir -p "$logs_posix" 2>/dev/null || true

  # Generar nombre de log único
  local timestamp
  timestamp="$(date +%Y%m%d_%H%M%S)"
  local log_name="ExcelSiigo_${funcion}_${timestamp}.log"
  # Usar \\ en vez de / para que el .exe de SIIGO entienda la ruta
  local log_path_win="${logs_dir//\//\\}/${log_name}"
  local log_path="$log_path_win"
  local log_posix
  log_posix="$(to_posix "$log_path")"

  # Reemplazar el placeholder NombreLog en extra_args[6] (pos 6: 0=exe,1=empresa,2=ano,3=func,4=norma,5=usu,6=clave,7=log)
  # Mejor: reconstruir la línea desde cero
  local cmd=()
  cmd+=("$(quote "$SIIGO_EXE")")
  cmd+=("$(quote "$SIIGO_EMPRESA")")
  cmd+=("$SIIGO_ANO")
  cmd+=("$funcion")
  cmd+=("$SIIGO_NORMA")
  cmd+=("$(quote "$SIIGO_USUARIO")")
  cmd+=("$(quote "$SIIGO_CLAVE")")
  cmd+=("$(quote "$log_path")")
  # Insertar resto de params (excepto NombreLog si venía en extra_args[0])
  cmd+=("${extra_args[@]}")

  # Inicio medición
  local start_ms
  start_ms=$(date +%s%3N 2>/dev/null || date +%s)000

  # Confirmación para PUSH*
  if is_destructive "$funcion" && [[ "$SIIGO_AUTO_CONFIRM" != "1" ]]; then
    echo "ADVERTENCIA: $funcion es una operación DESTRUCTIVA (importa datos a SIIGO)." >&2
    echo "Log: $log_path" >&2
    read -r -p "¿Confirmar ejecución? [s/N] " resp
    [[ "$resp" =~ ^[sSyY]$ ]] || { echo "Cancelado."; return 2; }
  fi

  # Validación: empresa debe estar en filepath.txt (a menos que --force)
  validate_company || return 1

  # Ejecutar el .exe. Estrategia simple: invocacion directa via bash/MSYS.
  # En sesiones Windows reales (Git Bash, PowerShell, WSL) esto funciona
  # correctamente. En el shell sandbox de Hermes hay un problema de
  # quoting con cmd.exe que NO ocurre alli (ver references/windows-msys-gotchas.md).
  set +e
  local exit_code
  "${cmd[@]}" >"$log_posix" 2>&1
  exit_code=$?
  set -e

  local end_ms
  end_ms=$(date +%s%3N 2>/dev/null || date +%s)000
  local duration=$((end_ms - start_ms))

  # Parsear log a JSON
  if [[ -f "$log_posix" ]]; then
    # Convertir rutas a formato Windows para python3 (uv + MSYS bug):
    # uv python no acepta rutas POSIX tipo /c/... y las corrompe a C:\c\...
    local py_script py_log
    if command -v cygpath >/dev/null 2>&1; then
      py_script="$(cygpath -w "${SCRIPT_DIR}/parse-log.py")"
      py_log="$(cygpath -w "$log_posix")"
    else
      py_script="${SCRIPT_DIR}/parse-log.py"
      py_log="$log_posix"
    fi
    python3 "$py_script" --log "$py_log" --funcion "$funcion" --exit "$exit_code" --duration "$duration" --logpath "$log_path"
  else
    # Si ni el log se generó, devolvemos error mínimo
    cat <<JSON
{"ok": false, "exit_code": $exit_code, "funcion": "$funcion", "log_path": "$log_path", "log_errors": ["No se generó archivo de log"], "duration_ms": $duration}
JSON
    return 1
  fi
}

# ----- Parseo de argumentos -------------------------------------------------

parse_args() {
  FUNCION="${1:-}"; shift || true

  # Normalizar a MAYÚSCULAS para case-insensitive
  if [[ -n "$FUNCION" ]]; then
    FUNCION="$(echo "$FUNCION" | tr '[:lower:]' '[:upper:]')"
  fi

  if [[ -z "$FUNCION" || "$FUNCION" == "--help" || "$FUNCION" == "-h" ]]; then
    print_help
    exit 0
  fi

  case "$FUNCION" in
    LIST)
      print_list
      exit 0
      ;;
    TEMPLATE)
      local target="${1:-}"
      if [[ -z "$target" ]]; then
        echo "ERROR: template requiere nombre de función" >&2
        exit 1
      fi
      FUNCION="$(echo "$target" | tr '[:lower:]' '[:upper:]')"
      # Modo plantilla: ConDatos=N + rango generico + salida a assets/templates
      EXTRA=("N" "0" "9999999999999" "C:\\temp\\template_${FUNCION}.xlsx" "T" "0" "99999999")
      return 0
      ;;
  esac

  # Parsear opciones de alto nivel (env-overridable)
  local cli_salida="" cli_entrada="" cli_errores=""
  local cli_fini="" cli_ffin="" cli_tipo=""
  local cli_comp_ini="" cli_comp_fin="" cli_nro_ini="" cli_nro_fin=""
  local cli_tercero_ini="" cli_tercero_fin=""
  local cli_cuenta_ini="" cli_cuenta_fin=""
  local cli_producto_ini="" cli_producto_fin=""
  local cli_bodega_ini="" cli_bodega_fin="" cli_mes=""
  local cli_clasif="" cli_estado="" cli_serial_ini="" cli_serial_fin=""
  local cli_acto_ini="" cli_acto_fin="" cli_consecutivo_ini="" cli_consecutivo_fin=""
  local cli_nit_ini="" cli_nit_fin="" cli_vendedor_ini="" cli_vendedor_fin=""
  local cli_cencos_ini="" cli_cencos_fin="" cli_subcencos_ini="" cli_subcencos_fin=""
  local cli_ano_ini="" cli_ano_fin="" cli_desde="" cli_hasta=""
  local cli_modelo="" cli_tipo_inf="" cli_moneda="" cli_desde_fap="" cli_hasta_fap=""
  local cli_datos="S"  # default: con datos

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --empresa)   SIIGO_EMPRESA="$2"; shift 2 ;;
      --ano)       SIIGO_ANO="$2"; shift 2 ;;
      --norma)     SIIGO_NORMA="$2"; shift 2 ;;
      --usuario)   SIIGO_USUARIO="$2"; shift 2 ;;
      --clave)     SIIGO_CLAVE="$2"; shift 2 ;;
      --logs)      SIIGO_LOGS="$2"; shift 2 ;;
      --yes)       SIIGO_AUTO_CONFIRM=1; shift ;;
      --force)     SIIGO_FORCE=1; shift ;;
      --offline)   cli_datos="N"; shift ;;
      --datos)     cli_datos="$2"; shift 2 ;;
      --fini)      cli_fini="$2"; shift 2 ;;
      --ffin)      cli_ffin="$2"; shift 2 ;;
      --tipo)      cli_tipo="$2"; shift 2 ;;
      --comp)      cli_comp_ini="$2"; cli_comp_fin="$3"; shift 3 ;;
      --nro)       cli_nro_ini="$2"; cli_nro_fin="$3"; shift 3 ;;
      --salida)    cli_salida="$2"; shift 2 ;;
      --entrada)   cli_entrada="$2"; shift 2 ;;
      --errores)   cli_errores="$2"; shift 2 ;;
      --tercero)   cli_tercero_ini="$2"; cli_tercero_fin="$3"; shift 3 ;;
      --cuenta)    cli_cuenta_ini="$2"; cli_cuenta_fin="$3"; shift 3 ;;
      --cta)       cli_cuenta_ini="$2"; cli_cuenta_fin="$3"; shift 3 ;;
      --producto|--prod)
                   cli_producto_ini="$2"; cli_producto_fin="$3"; shift 3 ;;
      --bodega|--bod)
                   cli_bodega_ini="$2"; cli_bodega_fin="$3"; shift 3 ;;
      --mes)       cli_mes="$2"; shift 2 ;;
      --desde)     cli_desde="$2"; shift 2 ;;
      --hasta)     cli_hasta="$2"; shift 2 ;;
      --clasif)    cli_clasif="$2"; shift 2 ;;
      --estado)    cli_estado="$2"; shift 2 ;;
      --serial)    cli_serial_ini="$2"; cli_serial_fin="$3"; shift 3 ;;
      --consecutivo) cli_consecutivo_ini="$2"; cli_consecutivo_fin="$3"; shift 3 ;;
      --act|--activo) cli_acto_ini="$2"; cli_acto_fin="$3"; shift 3 ;;
      --acteco)    cli_acto_ini="$2"; cli_acto_fin="$3"; shift 3 ;;
      --vendedor)  cli_vendedor_ini="$2"; cli_vendedor_fin="$3"; shift 3 ;;
      --cencos)    cli_cencos_ini="$2"; cli_cencos_fin="$3"; shift 3 ;;
      --subcencos) cli_subcencos_ini="$2"; cli_subcencos_fin="$3"; shift 3 ;;
      --nit)       cli_nit_ini="$2"; cli_nit_fin="$3"; shift 3 ;;
      --modelo)    cli_modelo="$2"; shift 2 ;;
      --tipo-inf)  cli_tipo_inf="$2"; shift 2 ;;
      --moneda)    cli_moneda="$2"; shift 2 ;;
      --*)         echo "Opción desconocida: $1" >&2; exit 1 ;;
      *)           EXTRA+=("$1"); shift ;;
    esac
  done

  # Construir la línea de args POSICIONALES según la firma de la función
  # (esto es lo que el .exe realmente entiende; mis flags --fini/--salida
  # son azucar sintáctico).
  EXTRA=()
  case "$FUNCION" in
    GETTER)
      # ConDatos TerceroInicial TerceroFinal ArchivoSalida Clasif DesdeFap HastaFap
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_tercero_ini:-1}")
      EXTRA+=("${cli_tercero_fin:-9999999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Terceros.xlsx}")
      EXTRA+=("${cli_clasif:-T}")
      EXTRA+=("${cli_desde_fap:-0}")
      EXTRA+=("${cli_hasta_fap:-99999999}")
      ;;
    GETMOV|GETMVT)
      # ConDatos FIni(MMDD) FFin(MMDD) TipoComp CompIni CompFin NroIni NroFin
      # ArchivoSalida ModeloBasico CtaIni CtaFin ProdIni ProdFin
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_fini:-0}")
      EXTRA+=("${cli_ffin:-9999}")
      EXTRA+=("${cli_tipo:-*}")
      EXTRA+=("${cli_comp_ini:-000}")
      EXTRA+=("${cli_comp_fin:-999}")
      EXTRA+=("${cli_nro_ini:-00000000001}")
      EXTRA+=("${cli_nro_fin:-99999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Movimiento.xlsx}")
      EXTRA+=("N")  # ModeloBasico = N (no basico) por default
      EXTRA+=("${cli_cuenta_ini:-0}")
      EXTRA+=("${cli_cuenta_fin:-9999999999}")
      EXTRA+=("${cli_producto_ini:-0}")
      EXTRA+=("${cli_producto_fin:-9999999999999}")
      ;;
    GETSAL)
      # ConDatos TerceroIni TerceroFin CtaIni CtaFin SaldoCtas ArchivoSalida
      # ACorteAnterior FechaCorte(MMDD)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_tercero_ini:-1}")
      EXTRA+=("${cli_tercero_fin:-9999999999999}")
      EXTRA+=("${cli_cuenta_ini:-0}")
      EXTRA+=("${cli_cuenta_fin:-9999999999}")
      EXTRA+=("C")  # SaldoCtas default = CxC
      EXTRA+=("${cli_salida:-C:\\Siigo\\SaldosCartera.xlsx}")
      EXTRA+=("N")  # ACorteAnterior = N
      EXTRA+=("0530")  # FechaCorte
      ;;
    GETBOD|GETBOP)
      # ConDatos ProdIni ProdFin BodegaIni BodegaFin MesCorte ArchivoSalida
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_producto_ini:-0010001000001}")
      EXTRA+=("${cli_producto_fin:-9999999999999}")
      EXTRA+=("${cli_bodega_ini:-0001}")
      EXTRA+=("${cli_bodega_fin:-9999}")
      EXTRA+=("${cli_mes:-12}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\SaldosPorBodega.xlsx}")
      ;;
    GETBODM)
      # ConDatos ProdIni ProdFin BodegaIni BodegaFin ArchivoSalida
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_producto_ini:-0010001000001}")
      EXTRA+=("${cli_producto_fin:-9999999999999}")
      EXTRA+=("${cli_bodega_ini:-0001}")
      EXTRA+=("${cli_bodega_fin:-9999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\MaxMinPorBodega.xlsx}")
      ;;
    GETINV)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_producto_ini:-0010001000001}")
      EXTRA+=("${cli_producto_fin:-9999999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Productos.xlsx}")
      ;;
    GETLIS)
      # ConDatos ProdIni ProdFin ArchivoSalida CodigoMoneda
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_producto_ini:-0010001000001}")
      EXTRA+=("${cli_producto_fin:-9999999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\ListasPrecio.xlsx}")
      EXTRA+=("${cli_moneda:-00}")
      ;;
    GETCTA)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_cuenta_ini:-0}")
      EXTRA+=("${cli_cuenta_fin:-9999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Cuentas.xlsx}")
      ;;
    GETACT)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_acto_ini:-1}")
      EXTRA+=("${cli_acto_fin:-999999999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Activos.xlsx}")
      ;;
    GETGRA)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_acto_ini:-1}")
      EXTRA+=("${cli_acto_fin:-9999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\GruposActivos.xlsx}")
      ;;
    GETVEN)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_vendedor_ini:-0001}")
      EXTRA+=("${cli_vendedor_fin:-9999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Vendedores.xlsx}")
      ;;
    GETCOS)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_cencos_ini:-0000}")
      EXTRA+=("${cli_cencos_fin:-9999}")
      EXTRA+=("${cli_subcencos_ini:-000}")
      EXTRA+=("${cli_subcencos_fin:-999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\CentrosCosto.xlsx}")
      ;;
    GETTBO)
      EXTRA+=("$cli_datos")
      EXTRA+=("${cli_bodega_ini:-0000}")
      EXTRA+=("${cli_bodega_fin:-9999}")
      EXTRA+=("${cli_acto_ini:-000}")
      EXTRA+=("${cli_acto_fin:-999}")
      EXTRA+=("${cli_salida:-C:\\Siigo\\Bodegas.xlsx}")
      ;;
    GETMUL|GETCIU|GETICA|GETKIT|GETPRE|GETSRL|GETMSRL|GETBSRL|GETHN|GETEMPL|GETNOV|GETINF)
      # Defaults seguros: ConDatos + rango generico + salida
      EXTRA+=("$cli_datos")
      EXTRA+=("0")
      EXTRA+=("9999999999999")
      EXTRA+=("${cli_salida:-C:\\Siigo\\${FUNCION}.xlsx}")
      ;;
    PUSHMOV|PUSHTER|PUSHINV|PUSHACT|PUSHGRA|PUSHLIN|PUSHLIS|PUSHKIT|PUSHPRE|PUSHCTA|PUSHMUL|PUSHICA|PUSHVEN|PUSHCOS|PUSHTBO|PUSHEXT|PUSHBODM|PUSHEMPL)
      # PUSH: nombre de archivo entrada + log errores
      EXTRA+=("${cli_entrada:-C:\\Siigo\\entrada.xlsx}")
      EXTRA+=("N")  # ModificaDocumentos
      EXTRA+=("N")  # FacturaBasica (solo MOV)
      EXTRA+=("${cli_errores:-C:\\Siigo\\errores.xlsx}")
      ;;
    *)
      # Funcion desconocida: paso lo que haya en EXTRA (no deberia llegar aqui)
      : ;;
  esac
}

# ----- Main ------------------------------------------------------------------

parse_args "$@"

# Validar que la función existe
if [[ ! " ${GET_FUNCS[@]} " =~ " ${FUNCION} " ]]; then
  echo "ERROR: función '$FUNCION' no reconocida." >&2
  echo "Ejecuta 'bash excel-siigo.sh list' para ver las disponibles." >&2
  exit 1
fi

# Si es template, sobreescribir salida a un archivo de assets
if [[ "$FUNCION" =~ GET.+$ ]]; then
  : # ya viene con salida en EXTRA
fi

run_excel_siigo "$FUNCION" "${EXTRA[@]}"
