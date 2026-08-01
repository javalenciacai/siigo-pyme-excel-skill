# ==============================================================================
#  excel-siigo.ps1 — Wrapper PowerShell para ExcelSIIGO.exe (SIIGO Pyme)
# ==============================================================================
#  Uso:
#     powershell -File excel-siigo.ps1 -Funcion GETMOV -FIni 0501 -FFin 0531 ...
#     powershell -File excel-siigo.ps1 -List
#     powershell -File excel-siigo.ps1 -Template GETTER
#     powershell -File excel-siigo.ps1 -Help
# =============================================================================

[CmdletBinding()]
param(
    [string]$Funcion,
    [switch]$List,
    [switch]$Template,
    [switch]$Help,
    [string]$Empresa,
    [string]$Ano,
    [string]$Norma = "L",
    [string]$Usuario,
    [string]$Clave,
    [string]$Logs,
    [string]$Salida,
    [string]$Entrada,
    [string]$Errores,
    [string]$FIni,
    [string]$FFin,
    [string]$Tipo,
    [string[]]$Comp,
    [string[]]$Nro,
    [string[]]$Tercero,
    [string[]]$Cuenta,
    [string[]]$Producto,
    [string[]]$Bodega,
    [string]$Mes,
    [string]$Clasif,
    [string]$Estado,
    [string]$TipoInf,
    [string]$Modelo,
    [string]$Moneda,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# ----- Defaults desde env vars ----------------------------------------------
$Script:SiigoExe    = $env:SIIGO_EXE
$Script:SiigoEmp    = $env:SIIGO_EMPRESA
$Script:SiigoUsr    = $env:SIIGO_USUARIO
$Script:SiigoClv    = $env:SIIGO_CLAVE
$Script:SiigoNorma  = if ($Norma) { $Norma } else { $env:SIIGO_NORMA }
$Script:SiigoLogs   = $env:SIIGO_LOGS
$Script:SiigoAno    = if ($Ano) { $Ano } else { $env:SIIGO_ANO }
$Script:AutoConfirm = $env:SIIGO_AUTO_CONFIRM

if (-not $Script:SiigoExe)   { $Script:SiigoExe   = "C:\Siigo\EXCELSIIGO.exe" }
if (-not $Script:SiigoEmp)   { $Script:SiigoEmp   = "C:\SIIWI01\" }
if (-not $Script:SiigoNorma) { $Script:SiigoNorma = "L" }
if (-not $Script:SiigoLogs)  { $Script:SiigoLogs  = "C:\SIIWI01\LOGS\" }
if (-not $Script:SiigoAno)   { $Script:SiigoAno   = (Get-Date).Year.ToString() }

if ($Empresa) { $Script:SiigoEmp = $Empresa }
if ($Usuario) { $Script:SiigoUsr = $Usuario }
if ($Clave)   { $Script:SiigoClv = $Clave }
if ($Logs)    { $Script:SiigoLogs = $Logs }
if ($Yes)     { $Script:AutoConfirm = "1" }

# ----- Catálogo de funciones (subset para validación) -----------------------
$Script:Funciones = @(
    "GETMOV","PUSHMOV","GETMVT",
    "GETTER","PUSHTER",
    "GETGRA","PUSHGRA","GETACT","PUSHACT",
    "GETEXT","PUSHEXT",
    "GETLIN","PUSHLIN","GETINV","PUSHINV","GETLIS","PUSHLIS","GETKIT","PUSHKIT","GETPRE","PUSHPRE",
    "GETBOD","GETBOP","GETBODM","PUSHBODM",
    "GETSAL",
    "GETCTA","PUSHCTA","GETMUL","PUSHMUL","GETICA","PUSHICA",
    "GETCIU","GETVEN","PUSHVEN","GETCOS","PUSHCOS","GETTBO","PUSHTBO",
    "GETSRL","GETMSRL","GETBSRL",
    "GETHN","GETEMPL","PUSHEMPL","GETNOV",
    "GETINF"
)

# ----- Helpers --------------------------------------------------------------
function Show-Help {
@"
excel-siigo.ps1 — Wrapper PowerShell para ExcelSIIGO.exe

USO:
  powershell -File excel-siigo.ps1 -Funcion <F> [opciones]
  powershell -File excel-siigo.ps1 -List
  powershell -File excel-siigo.ps1 -Template <F>
  powershell -File excel-siigo.ps1 -Help

OPCIONES PRINCIPALES:
  -Empresa <ruta>   -Ano <yyyy>   -Norma L|N   -Usuario <8c>
  -Clave <8c>       -Logs <ruta>  -Yes
  -Salida <xlsx>    -Entrada <xlsx>   -Errores <xlsx>
  -FIni <MMDD>      -FFin <MMDD> -Tipo <c>
  -Comp <ini> <fin> -Nro <ini> <fin>
  -Tercero <ini> <fin> -Cuenta <ini> <fin> -Producto <ini> <fin>
  -Bodega <ini> <fin> -Mes <mm>
  -Clasif <T|C|P|O> -Estado <D|N|T> -TipoInf <B|BCC> -Modelo <c> -Moneda <cc>

EJEMPLOS:
  powershell -File excel-siigo.ps1 -Funcion GETMOV -FIni 0501 -FFin 0531 `
      -Tipo F -Comp 001 -Comp 002 -Nro 00000000001 -Nro 99999999999 `
      -Salida C:\SIIWI01\Movimiento.xlsx
  powershell -File excel-siigo.ps1 -Funcion PUSHTER `
      -Entrada C:\SIIWI01\Terceros.xlsx `
      -Errores C:\SIIWI01\LOGS\ErrorTer.xlsx -Yes
"@
}

function Test-Destructive {
    param([string]$F)
    $F -like "PUSH*"
}

function Get-LogPath {
    param([string]$Funcion)
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $name = "ExcelSiigo_${Funcion}_${ts}.log"
    Join-Path $Script:SiigoLogs $name
}

# ----- Listar ---------------------------------------------------------------
if ($List) {
    Write-Host "Funciones disponibles ($($Script:Funciones.Count)):"
    foreach ($f in $Script:Funciones) {
        $kind = if ($f -like "PUSH*") { "PUSH" } else { "GET" }
        Write-Host ("  {0,-12}  {1}" -f $f, $kind)
    }
    exit 0
}

if ($Help) {
    Show-Help
    exit 0
}

if (-not $Funcion) {
    Show-Help
    exit 1
}

if ($Template) {
    # Sobrescribir Funcion con el argumento siguiente
    # PowerShell no permite positional tras [switch]; usamos argumento extra
    $target = $args[0]
    if (-not $target) { Write-Error "Template requiere nombre de función"; exit 1 }
    $Funcion = $target
}

# Validar función
if ($Script:Funciones -notcontains $Funcion) {
    Write-Error "Función '$Funcion' no reconocida. Usa -List para ver las disponibles."
    exit 1
}

# Validaciones básicas
if (-not (Test-Path $Script:SiigoExe)) {
    Write-Error "ExcelSIIGO.exe no encontrado en: $Script:SiigoExe"
    exit 1
}
if (-not $Script:SiigoUsr -or -not $Script:SiigoClv) {
    Write-Error "SIIGO_USUARIO y SIIGO_CLAVE son obligatorios (o pasa -Usuario/-Clave)"
    exit 1
}

# Crear carpeta LOGS
if (-not (Test-Path $Script:SiigoLogs)) {
    New-Item -ItemType Directory -Path $Script:SiigoLogs -Force | Out-Null
}

# Construir argumentos del .exe
$logPath = Get-LogPath -Funcion $Funcion

$argList = @(
    "`"$Script:SiigoEmp`"",
    "`"$Script:SiigoAno`"",
    "`"$Funcion`"",
    "`"$Script:SiigoNorma`"",
    "`"$Script:SiigoUsr`"",
    "`"$Script:SiigoClv`"",
    "`"$logPath`""
)

# Añadir params según función
function Add-If { param($cond, $val) if ($cond) { $Script:argList += "`"$val`"" } }

Add-If $true "S"  # ConDatos por defecto S
Add-If $FIni   $FIni
Add-If $FFin   $FFin
Add-If $Tipo   $Tipo
if ($Comp)    { $Script:argList += $Comp | ForEach-Object { "`"$_`"" } }
if ($Nro)     { $Script:argList += $Nro  | ForEach-Object { "`"$_`"" } }
Add-If $Salida  $Salida
Add-If $Entrada $Entrada
Add-If $Errores $Errores
if ($Tercero) { $Script:argList += $Tercero | ForEach-Object { "`"$_`"" } }
if ($Cuenta)  { $Script:argList += $Cuenta  | ForEach-Object { "`"$_`"" } }
if ($Producto){ $Script:argList += $Producto| ForEach-Object { "`"$_`"" } }
if ($Bodega)  { $Script:argList += $Bodega  | ForEach-Object { "`"$_`"" } }
Add-If $Mes $Mes
Add-If $Clasif $Clasif
Add-If $Estado $Estado
Add-If $TipoInf $TipoInf
Add-If $Modelo $Modelo
Add-If $Moneda $Moneda

# Confirmación para PUSH*
if ((Test-Destructive $Funcion) -and $Script:AutoConfirm -ne "1") {
    Write-Warning "Operación DESTRUCTIVA: $Funcion importa datos a SIIGO."
    Write-Warning "Log: $logPath"
    $resp = Read-Host "¿Confirmar? [s/N]"
    if ($resp -notmatch "^[sSyY]$") {
        Write-Host "Cancelado."
        exit 2
    }
}

# Ejecutar
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Script:SiigoExe
foreach ($a in $argList) { $psi.ArgumentList.Add($a) }
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false

$proc = [System.Diagnostics.Process]::Start($psi)
$out = $proc.StandardOutput.ReadToEnd()
$err = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()
$sw.Stop()
$exitCode = $proc.ExitCode

# Guardar .LOG
$out | Out-File -FilePath $logPath -Encoding utf8

# Parsear con Python si está disponible; si no, JSON básico
$py = (Get-Command python3 -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if ($py) {
    & $py.Source "$PSScriptRoot\parse-log.py" --log $logPath --funcion $Funcion --exit $exitCode --duration $sw.ElapsedMilliseconds --logpath $logPath
} else {
    $errSafe = ($err -replace "`r?`n"," ") -replace '"','\"'
    $outSafe = ($out -replace "`r?`n"," ") -replace '"','\"'
    $json = @"
{"ok": $(if($exitCode -eq 0){'true'}else{'false'}), "exit_code": $exitCode, "funcion": "$Funcion", "log_path": "$logPath", "stdout": "$outSafe", "stderr": "$errSafe", "duration_ms": $($sw.ElapsedMilliseconds)}
"@
    Write-Output $json
}
