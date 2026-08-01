#!/usr/bin/env bash
# =============================================================================
#  check-prereqs.sh — Valida entorno antes de invocar ExcelSIIGO.exe
# =============================================================================
#  Comprueba:
#   1. ExcelSIIGO.exe existe y es ejecutable.
#   2. La carpeta de empresa existe y parece válida.
#   3. La carpeta LOGS existe y es escribible.
#   4. No hay otra instancia de ExcelSIIGO.exe corriendo.
#   5. Python3 disponible (para parse-log.py).
#   6. (Windows) PowerShell disponible.
# =============================================================================

set -uo pipefail

EXIT_CODE=0
WARNINGS=()
ERRORS=()

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARNINGS+=("$1"); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; ERRORS+=("$1"); EXIT_CODE=1; }

SIIGO_EXE="${SIIGO_EXE:-C:\\Siigo\\EXCELSIIGO.exe}"
SIIGO_EMPRESA="${SIIGO_EMPRESA:-C:\\SIIWI01\\}"
SIIGO_LOGS="${SIIGO_LOGS:-C:\\SIIWI01\\LOGS\\}"

echo "Verificando prerrequisitos para ExcelSIIGO.exe..."
echo

# 1. Binario
echo "1. Binario ExcelSIIGO.exe"
posix_exe="$(cygpath -u "$SIIGO_EXE" 2>/dev/null || echo "$SIIGO_EXE")"
if [[ -f "$posix_exe" ]]; then
  ok "Encontrado: $SIIGO_EXE"
  if [[ -x "$posix_exe" ]]; then
    ok "Es ejecutable"
  else
    warn "Existe pero no es ejecutable (puede ser OK en Windows con cmd)"
  fi
else
  fail "No encontrado: $SIIGO_EXE"
fi
echo

# 2. Carpeta empresa
echo "2. Carpeta de empresa"
posix_emp="$(cygpath -u "$SIIGO_EMPRESA" 2>/dev/null || echo "$SIIGO_EMPRESA")"
if [[ -d "$posix_emp" ]]; then
  ok "Existe: $SIIGO_EMPRESA"
  # Buscar archivos típicos de empresa SIIGO
  gnt_count=$(find "$posix_emp" -maxdepth 2 -name "*.gnt" 2>/dev/null | wc -l)
  if [[ $gnt_count -gt 0 ]]; then
    ok "Contiene $gnt_count archivos .gnt (parece empresa SIIGO válida)"
  else
    warn "No se encontraron archivos .gnt en la carpeta"
  fi
else
  fail "No existe: $SIIGO_EMPRESA"
fi
echo

# 3. Carpeta LOGS
echo "3. Carpeta LOGS"
posix_logs="$(cygpath -u "$SIIGO_LOGS" 2>/dev/null || echo "$SIIGO_LOGS")"
if [[ -d "$posix_logs" ]]; then
  ok "Existe: $SIIGO_LOGS"
  if [[ -w "$posix_logs" ]]; then
    ok "Escribible"
  else
    fail "No escribible: $SIIGO_LOGS"
  fi
else
  warn "No existe: $SIIGO_LOGS (se creará al ejecutar)"
fi
echo

# 4. Instancia única
echo "4. Instancias en ejecución"
if command -v tasklist >/dev/null 2>&1; then
  running=$(tasklist //FI "IMAGENAME eq EXCELSIIGO.exe" 2>/dev/null | grep -c "EXCELSIIGO.exe" || true)
  if [[ $running -gt 0 ]]; then
    warn "Hay $running instancia(s) de EXCELSIIGO.exe corriendo. Cierra antes de ejecutar."
  else
    ok "Sin instancias en ejecución"
  fi
elif command -v pgrep >/dev/null 2>&1; then
  running=$(pgrep -f EXCELSIIGO.exe 2>/dev/null | wc -l)
  if [[ $running -gt 0 ]]; then
    warn "Hay proceso(s) EXCELSIIGO.exe corriendo (pgrep)"
  else
    ok "Sin instancias en ejecución"
  fi
else
  warn "No se pudo verificar (ni tasklist ni pgrep)"
fi
echo

# 5. Python3
echo "5. Intérprete Python"
if command -v python3 >/dev/null 2>&1; then
  ok "python3: $(python3 --version 2>&1)"
elif command -v python >/dev/null 2>&1; then
  ok "python: $(python --version 2>&1)"
else
  warn "No se encontró python3 (parse-log.py no funcionará)"
fi
echo

# 6. PowerShell (solo en Windows)
echo "6. PowerShell"
if command -v powershell >/dev/null 2>&1; then
  ok "powershell: $(powershell -Command '$PSVersionTable.PSVersion.ToString()' 2>&1)"
elif command -v pwsh >/dev/null 2>&1; then
  ok "pwsh: $(pwsh -Command '$PSVersionTable.PSVersion.ToString()' 2>&1)"
else
  warn "PowerShell no disponible (opcional; el wrapper .ps1 no funcionará)"
fi
echo

# Resumen
echo "════════════════════════════════════════"
if [[ $EXIT_CODE -eq 0 ]]; then
  printf '\033[32m✔ Entorno OK\033[0m'
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    printf ' con %d advertencia(s)' "${#WARNINGS[@]}"
  fi
  echo
  exit 0
else
  printf '\033[31m✘ Entorno NO listo\033[0m — %d error(es)' "${#ERRORS[@]}"
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    printf ', %d advertencia(s)' "${#WARNINGS[@]}"
  fi
  echo
  echo
  echo "Errores:"
  printf '  - %s\n' "${ERRORS[@]}"
  exit 1
fi
