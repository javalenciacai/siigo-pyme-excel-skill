#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
parse-log.py — Parsea el .LOG de ExcelSIIGO.exe a JSON.

Uso:
    python parse-log.py --log C:/SIIWI01/LOGS/ExcelSiigo.log
    python parse-log.py --log C:/SIIWI01/LOGS/ExcelSiigo.log --funcion GETMOV --exit 0 \\
                        --duration 1823 --logpath <ruta>

Decodifica el log como Windows-1252 (el CLI genera cp1252), extrae líneas
con ERROR o código 070, y devuelve JSON con ok, exit_code, log_errors, tail.
"""

import argparse
import json
import sys
from pathlib import Path


def parse_log(path: Path) -> dict:
    if not path.exists():
        return {"ok": False, "error": f"Log no encontrado: {path}", "ok_hint": False, "log_lines": 0, "log_errors": [], "tail": ""}
    raw = path.read_bytes()
    if not raw:
        # Log vacío: el proceso terminó sin escribir nada. Lo tratamos como
        # "sin error conocido" — el agente decide según el exit_code.
        return {"ok_hint": True, "log_lines": 0, "log_errors": [], "tail": ""}
    try:
        text = raw.decode("cp1252")
    except UnicodeDecodeError:
        text = raw.decode("cp1252", errors="replace")

    lines = [ln.rstrip() for ln in text.splitlines()]
    errors = []
    for ln in lines:
        s = ln.strip()
        if not s:
            continue
        if "ERROR" in s.upper() or s.startswith("070") or "no se encuentra" in s.lower():
            errors.append(s)

    # Tail: últimas 20 líneas no vacías
    non_empty = [ln for ln in lines if ln.strip()]
    tail = "\n".join(non_empty[-20:])

    return {
        "log_lines": len(lines),
        "log_errors": errors,
        "tail": tail,
        "ok_hint": (len(errors) == 0),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True, help="Ruta al .LOG")
    ap.add_argument("--funcion", default="")
    ap.add_argument("--exit", type=int, default=0)
    ap.add_argument("--duration", type=int, default=0)
    ap.add_argument("--logpath", default="")
    args = ap.parse_args()

    parsed = parse_log(Path(args.log))
    ok = parsed.pop("ok_hint") and (args.exit == 0)
    out = {
        "ok": ok,
        "exit_code": args.exit,
        "funcion": args.funcion,
        "log_path": args.logpath or args.log,
        "duration_ms": args.duration,
        **parsed,
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
