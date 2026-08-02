#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
parse-filepath.py — Lee el filepath.txt de una instalación SIIGO Pyme.

Funcionalidad principal: parsea el archivo que SIIGO Pyme crea junto al
EXCELSIIGO.exe y devuelve la ruta de la empresa a la que apunta esa
instalación. Soporta dos modos de uso:

1) Modo validación (usado internamente por excel-siigo.sh):
       python parse-filepath.py --exe C:/Siigo/EXCELSIIGO.exe \
                                 --empresa Z:/SIIWI01/
   Devuelve JSON con `empresa_match_found` (True/False).

2) Modo detección (útil para que el usuario descubra la ruta correcta):
       python parse-filepath.py --exe C:/Siigo/EXCELSIIGO.exe
   Imprime la ruta detectada y un comando bash listo para source.

Formato del archivo (single pointer, NO es un índice):
    Z:\\SIIWI01\\::\\127.0.0.1\inmunotek::

Tres campos separados por '::':
    1. Ruta local / de red de la empresa (ej. "Z:\\SIIWI01\\")
    2. Ruta UNC del servidor de origen (ej. "\\127.0.0.1\inmunotek")
    3. (opcional) Campo extra (normalmente vacío)
"""

from __future__ import annotations
import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional


def parse_filepath(raw: str) -> dict:
    """Parsea el contenido crudo de filepath.txt.

    IMPORTANTE: filepath.txt NO es un índice de todas las empresas
    disponibles. Es un puntero a UNA sola empresa — la empresa a la que
    esta instalación específica de EXCELSIIGO.exe está apuntando.
    """
    partes = raw.split("::")
    ruta_local = partes[0].strip() if len(partes) > 0 else ""
    ruta_unc = partes[1].strip() if len(partes) > 1 else ""

    m = re.search(r"SIIWI(\d+)", ruta_local, re.IGNORECASE)
    empresa_id = m.group(1) if m else ""

    empresas = []
    if ruta_local or ruta_unc:
        empresas.append({
            "id": empresa_id,
            "ruta": ruta_local,
            "unc": ruta_unc,
        })

    return {
        "raw": raw.strip(),
        "empresa_local": ruta_local,
        "empresa_unc": ruta_unc,
        "empresa_id": empresa_id,
        "empresas_declaradas": empresas,  # siempre 1, lo del filepath.txt
        "_nota": (
            "filepath.txt solo declara 1 empresa (la de esta instalación). "
            "Otras empresas pueden existir en rutas SIIWI02, SIIWI03, etc. "
            "pero no aparecen aquí — hay que escanear el filesystem."
        ),
    }


def find_filepath(exe_path: str) -> Optional[Path]:
    """Localiza filepath.txt junto al ejecutable. Acepta POSIX/Windows/MSYS."""
    candidates = []
    p = Path(exe_path)
    if p.exists():
        candidates.append(p)
    candidates.append(Path(str(exe_path).replace("/", "\\")))
    cyg = shutil.which("cygpath")
    if cyg:
        try:
            r = subprocess.run([cyg, "-w", exe_path], capture_output=True, text=True, timeout=5)
            if r.returncode == 0 and r.stdout.strip():
                candidates.append(Path(r.stdout.strip()))
        except Exception:
            pass
    for p in candidates:
        if p.exists():
            ft = p.parent / "filepath.txt"
            if ft.exists():
                return ft
    return None


def main():
    ap = argparse.ArgumentParser(
        description="Parsea filepath.txt de una instalación SIIGO Pyme")
    ap.add_argument("--file", help="Ruta directa a filepath.txt")
    ap.add_argument("--exe", help="Ruta al EXCELSIIGO.exe (busca filepath.txt en su carpeta)")
    ap.add_argument("--contains", help="Buscar match por substring (ej. SIIWI02 o 02)")
    ap.add_argument("--empresa", help="Ruta de empresa solicitada (para validar)")
    args = ap.parse_args()

    if args.file:
        path = Path(args.file)
    elif args.exe:
        path = find_filepath(args.exe)
        if not path:
            out = {"exists": False, "error": f"filepath.txt no encontrado junto a {args.exe}"}
            print(json.dumps(out, ensure_ascii=False, indent=2))
            return 1
    else:
        ap.error("Debes pasar --file o --exe")

    if not path.exists():
        out = {"exists": False, "error": f"No existe: {path}"}
        print(json.dumps(out, ensure_ascii=False, indent=2))
        return 1

    raw = path.read_text(encoding="cp1252", errors="replace")
    parsed = parse_filepath(raw)
    out = {
        "exists": True,
        "path": str(path),
        **parsed,
    }

    # Buscar match por substring
    match = None
    if args.contains:
        needle = args.contains.lower()
        for emp in parsed["empresas_declaradas"]:
            if (needle in emp["id"].lower()
                or needle in emp["ruta"].lower()
                or needle in emp["unc"].lower()):
                match = emp
                break
        out["match"] = match
        out["requested"] = args.contains
        out["match_found"] = match is not None

    # Validar empresa solicitada
    if args.empresa:
        emp_norm = args.empresa.replace("/", "\\").lower().rstrip("\\")
        match_emp = None
        for emp in parsed["empresas_declaradas"]:
            if emp["ruta"].replace("\\", "").lower().rstrip("\\") == emp_norm.replace("\\", ""):
                match_emp = emp
                break
        out["requested_empresa"] = args.empresa
        out["empresa_match"] = match_emp
        out["empresa_match_found"] = match_emp is not None

    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0 if (out.get("match_found", True) and out.get("empresa_match_found", True)) else 2


if __name__ == "__main__":
    sys.exit(main())
