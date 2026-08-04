#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
excel-siigo.py — Wrapper Python multiplataforma para ExcelSIIGO.exe.

Uso:
    from excel_siigo import run
    result = run("GETMOV", salida="C:/SIIWI01/Mov.xlsx", fini="0501", ffin="0531",
                 tipo="F", comp=("001","002"), nro=("00000000001","99999999999"))
    print(result)

CLI:
    python excel-siigo.py list
    python excel-siigo.py getmov --fini 0501 --ffin 0531 --salida out.xlsx
    python excel-siigo.py pushter --entrada in.xlsx --errores err.xlsx --yes

Limitaciones:
    - Diseñado para Windows. En Linux/macOS requiere Wine + el .exe
      montado en una ruta accesible.
    - El wrapper construye la línea de comandos exactamente como el manual
      oficial. Cualquier param nuevo hay que añadirlo aquí.
"""

from __future__ import annotations
import argparse
import json
import os
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional, Sequence


# Catálogo de funciones soportadas
FUNCIONES = (
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
    "GETINF",
)


@dataclass
class Config:
    siigo_exe: str = "C:\\Siigo\\EXCELSIIGO.exe"
    empresa:   str = ""  # sin default: detect via filepath.txt
    usuario:   str = ""
    clave:     str = ""
    norma:     str = "L"
    logs:      str = ""  # sin default: misma carpeta que --salida
    ano:       str = ""
    auto_confirm: bool = False

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            siigo_exe=os.environ.get("SIIGO_EXE", cls.siigo_exe),
            empresa=os.environ.get("SIIGO_EMPRESA", cls.empresa),
            usuario=os.environ.get("SIIGO_USUARIO", ""),
            clave=os.environ.get("SIIGO_CLAVE", ""),
            norma=os.environ.get("SIIGO_NORMA", "L"),
            logs=os.environ.get("SIIGO_LOGS", cls.logs),
            ano=os.environ.get("SIIGO_ANO", time.strftime("%Y")),
            auto_confirm=os.environ.get("SIIGO_AUTO_CONFIRM", "0") == "1",
        )


@dataclass
class Result:
    ok: bool
    exit_code: int
    funcion: str
    log_path: str
    log_lines: int = 0
    log_errors: list = field(default_factory=list)
    duration_ms: int = 0
    output_file: Optional[str] = None
    tail: str = ""

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2)


def _is_destructive(funcion: str) -> bool:
    return funcion.upper().startswith("PUSH")


def _build_argv(cfg: Config, funcion: str, log_path: str, params: Sequence[str]) -> list:
    return [
        cfg.siigo_exe,
        cfg.empresa,
        cfg.ano,
        funcion,
        cfg.norma,
        cfg.usuario,
        cfg.clave,
        log_path,
        *params,
    ]


def _ensure_logs_dir(path: str) -> None:
    p = Path(path)
    # Si parece ruta Windows, intentar crear tal cual
    try:
        p.mkdir(parents=True, exist_ok=True)
    except OSError:
        # Si falla (WSL u otro), intentar tratar como POSIX
        Path(path.replace("\\", "/")).mkdir(parents=True, exist_ok=True)


def _log_tail(path: Path, n: int = 20) -> str:
    try:
        with open(path, "rb") as f:
            raw = f.read()
        try:
            text = raw.decode("cp1252")
        except UnicodeDecodeError:
            text = raw.decode("cp1252", errors="replace")
        lines = [ln for ln in text.splitlines() if ln.strip()]
        return "\n".join(lines[-n:])
    except OSError as e:
        return f"<no se pudo leer log: {e}>"


def _extract_errors(text: str) -> list:
    errors = []
    for ln in text.splitlines():
        u = ln.strip()
        if not u:
            continue
        if "ERROR" in u.upper() or u.startswith("070"):
            errors.append(u)
    return errors


def run(funcion: str, *, params: Optional[Sequence[str]] = None,
        config: Optional[Config] = None, output_file: Optional[str] = None,
        confirm_destructive: Optional[bool] = None) -> Result:
    """Ejecuta ExcelSIIGO.exe con la función indicada.

    Args:
        funcion: nombre de función (p.ej. "GETMOV").
        params: lista de parámetros posicionales específicos de la función.
        config: configuración (si no, se lee del entorno).
        output_file: ruta del archivo XLSX de salida (para incluir en el resultado).
        confirm_destructive: si True, salta la confirmación para PUSH*.
    """
    cfg = config or Config.from_env()
    funcion = funcion.upper()
    if funcion not in FUNCIONES:
        raise ValueError(f"Función '{funcion}' no reconocida. "
                         f"Usa FUNCIONES para ver las disponibles.")

    if not cfg.usuario or not cfg.clave:
        raise ValueError("SIIGO_USUARIO y SIIGO_CLAVE son obligatorios")
    if not Path(cfg.siigo_exe).exists() and not os.path.exists(cfg.siigo_exe):
        raise FileNotFoundError(f"ExcelSIIGO.exe no encontrado: {cfg.siigo_exe}")

    # Determinar carpeta de logs. Prioridad:
    #   1) cfg.logs (viene de $SIIGO_LOGS o --logs)
    #   2) directorio del archivo de salida (--salida o primer .xlsx en params)
    #   3) cwd
    logs_dir = cfg.logs
    if not logs_dir:
        for p in params or []:
            if isinstance(p, str) and (p.endswith(".xlsx") or p.endswith(".xls")):
                logs_dir = str(Path(p).parent)
                break
    if not logs_dir:
        logs_dir = "."

    _ensure_logs_dir(logs_dir)
    ts = time.strftime("%Y%m%d_%H%M%S")
    log_name = f"ExcelSiigo_{funcion}_{ts}.log"
    log_path = str(Path(logs_dir) / log_name)

    # Crear carpetas de salida y log si no existen. El .exe de SIIGO NO
    # crea carpetas, sale silenciosamente si la carpeta destino no existe.
    _ensure_logs_dir(str(Path(log_path).parent))
    for p in params or []:
        if isinstance(p, str) and (p.endswith(".xlsx") or p.endswith(".xls")):
            _ensure_logs_dir(str(Path(p).parent))

    argv = _build_argv(cfg, funcion, log_path, list(params or []))

    # Confirmación destructiva
    if _is_destructive(funcion):
        skip = confirm_destructive if confirm_destructive is not None else cfg.auto_confirm
        if not skip:
            sys.stderr.write(
                f"\n⚠️  ADVERTENCIA: {funcion} es DESTRUCTIVA (importa datos a SIIGO).\n"
                f"Log: {log_path}\n"
                "¿Confirmar? [s/N]: "
            )
            try:
                resp = input()
            except EOFError:
                resp = ""
            if resp.strip().lower() not in ("s", "si", "y", "yes"):
                return Result(
                    ok=False, exit_code=2, funcion=funcion, log_path=log_path,
                    log_errors=["Cancelado por el usuario"],
                )

    # Ejecutar. NO redirigimos stdout/stderr — dejamos que el .exe
    # escriba su propio .log (que SÍ escribe con "000 Ejecución Exitosa"
    # cuando todo va bien). Redirigir a un pipe causaría que el log_lines
    # se lea antes de que el .exe termine de escribir, y que el archivo
    # final quede en 0 bytes por el handle abierto.
    start = time.time()
    try:
        completed = subprocess.run(
            argv,
            capture_output=False,  # el .exe maneja su propio log
            check=False,
        )
        exit_code = completed.returncode
    except FileNotFoundError as e:
        return Result(
            ok=False, exit_code=127, funcion=funcion, log_path=log_path,
            log_errors=[f"No se pudo ejecutar el binario: {e}"],
        )
    duration_ms = int((time.time() - start) * 1000)

    # Parsear log
    tail = _log_tail(Path(log_path))
    errors = _extract_errors(tail)
    line_count = tail.count("\n") + (0 if tail.endswith("\n") else 1)

    ok = (exit_code == 0) and not errors

    return Result(
        ok=ok,
        exit_code=exit_code,
        funcion=funcion,
        log_path=log_path,
        log_lines=line_count,
        log_errors=errors,
        duration_ms=duration_ms,
        output_file=output_file,
        tail=tail,
    )


# ----- CLI -------------------------------------------------------------------

def _cli():
    p = argparse.ArgumentParser(prog="excel-siigo.py",
                                description="Wrapper Python para ExcelSIIGO.exe")
    p.add_argument("funcion", nargs="?", help="GETMOV, PUSHTER, ... o 'list'")
    p.add_argument("--fini"); p.add_argument("--ffin")
    p.add_argument("--tipo"); p.add_argument("--comp", nargs=2, metavar=("INI","FIN"))
    p.add_argument("--nro",  nargs=2, metavar=("INI","FIN"))
    p.add_argument("--salida"); p.add_argument("--entrada"); p.add_argument("--errores")
    p.add_argument("--tercero", nargs=2, metavar=("INI","FIN"))
    p.add_argument("--cuenta",  nargs=2, metavar=("INI","FIN"))
    p.add_argument("--producto",nargs=2, metavar=("INI","FIN"))
    p.add_argument("--bodega",  nargs=2, metavar=("INI","FIN"))
    p.add_argument("--mes"); p.add_argument("--clasif"); p.add_argument("--estado")
    p.add_argument("--tipo-inf"); p.add_argument("--modelo"); p.add_argument("--moneda")
    p.add_argument("--yes", action="store_true")
    p.add_argument("--list", action="store_true")
    args = p.parse_args()

    if args.list or (args.funcion == "list"):
        print(f"Funciones disponibles ({len(FUNCIONES)}):")
        for f in FUNCIONES:
            kind = "PUSH" if f.startswith("PUSH") else "GET "
            print(f"  {kind}  {f}")
        return 0

    if not args.funcion:
        p.print_help()
        return 1

    # Recoger params posicionales
    params = ["S"]  # ConDatos = S
    def add(x): 
        if x is not None: params.append(str(x))
    add(args.fini); add(args.ffin); add(args.tipo)
    if args.comp:   params.extend(args.comp)
    if args.nro:    params.extend(args.nro)
    add(args.salida or args.entrada)
    add(args.errores)
    if args.tercero: params.extend(args.tercero)
    if args.cuenta:  params.extend(args.cuenta)
    if args.producto:params.extend(args.producto)
    if args.bodega:  params.extend(args.bodega)
    add(args.mes); add(args.clasif); add(args.estado)
    add(args.tipo_inf); add(args.modelo); add(args.moneda)

    result = run(args.funcion, params=params, output_file=args.salida, confirm_destructive=args.yes)
    print(result.to_json())
    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(_cli())
