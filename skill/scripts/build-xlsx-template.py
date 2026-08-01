#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build-xlsx-template.py — Genera un .xlsx vacío (sólo encabezados) usando
ExcelSIIGO.exe con ConDatos=N.

Uso:
    python build-xlsx-template.py GETTER --salida assets/templates/GETTER_template.xlsx
    python build-xlsx-template.py GETMOV --fini 0501 --ffin 0531 --salida ...

Para que esto funcione, el CLI debe estar accesible y la empresa configurada.
Si no, sólo imprime la estructura esperada de columnas basándose en la
documentación (modo offline).
"""

import argparse
import os
import sys
from pathlib import Path

# Estructura de columnas conocidas (subset) — para modo offline
COLUMNAS_CONOCIDAS = {
    "GETMOV":  ["CUENTA","NOMBRE_CUENTA","DEBITO","CREDITO","TERCERO","NOMBRE_TERCERO",
                "FECHA","TIPO_COMP","COMP","NUMERO","DETALLE","PRODUCTO","CANTIDAD",
                "VALOR_UNITARIO","VALOR_TOTAL","CENTRO_COSTO","SUBCENTRO","BASE_GRAVADA",
                "IVA","RETENCION","TOTAL_DOCUMENTO","MODELO_BASICO"],
    "PUSHMOV": ["CUENTA","NOMBRE_CUENTA","DEBITO","CREDITO","TERCERO","NOMBRE_TERCERO",
                "FECHA","TIPO_COMP","COMP","NUMERO","DETALLE","PRODUCTO","CANTIDAD",
                "VALOR_UNITARIO","VALOR_TOTAL","CENTRO_COSTO","SUBCENTRO","BASE_GRAVADA",
                "IVA","RETENCION","TOTAL_DOCUMENTO","MODELO_BASICO"],
    "GETTER":  ["TIPO_DOC","NIT","DIGITO","NOMBRE","DIRECCION","CIUDAD","TELEFONO",
                "EMAIL","CLASIFICACION","CUENTA","REGIMEN","AUTORETENEDOR","RUTA",
                "FECHA_APERTURA","CONTACTO","CARGO_CONTACTO","OBSERVACIONES"],
    "PUSHTER": ["TIPO_DOC","NIT","DIGITO","NOMBRE","DIRECCION","CIUDAD","TELEFONO",
                "EMAIL","CLASIFICACION","CUENTA","REGIMEN","AUTORETENEDOR","RUTA",
                "FECHA_APERTURA","CONTACTO","CARGO_CONTACTO","OBSERVACIONES"],
    "GETINV":  ["LINEA","GRUPO","PRODUCTO","NOMBRE","UND_MEDIDA","REFERENCIA","COD_BARRAS",
                "TIPO_PRODUCTO","CLASIFICACION","CUENTA_INGRESO","CUENTA_INVENTARIO",
                "CUENTA_COSTO","PRECIO_1","PRECIO_2","PRECIO_3","IVA","EXISTENCIA_MIN",
                "EXISTENCIA_MAX","PESO","VOLUMEN","ACTIVO","OBSERVACIONES"],
    "PUSHINV": ["LINEA","GRUPO","PRODUCTO","NOMBRE","UND_MEDIDA","REFERENCIA","COD_BARRAS",
                "TIPO_PRODUCTO","CLASIFICACION","CUENTA_INGRESO","CUENTA_INVENTARIO",
                "CUENTA_COSTO","PRECIO_1","PRECIO_2","PRECIO_3","IVA","EXISTENCIA_MIN",
                "EXISTENCIA_MAX","PESO","VOLUMEN","ACTIVO","OBSERVACIONES"],
    "GETCTA":  ["CUENTA","NOMBRE","NATURALEZA","TIPO","NIVEL","CTA_PADRE","CTA_AJUSTE",
                "CTA_NIIF","CTA_NIIF_AJUSTE","PORCENTAJE","CTA_BASE","CTA_RETENCION",
                "CTA_IVA","CTA_ICA","PORC_ICA","GRUPO","CLASE","ESTADO","OBSERVACIONES"],
    "GETACT":  ["GRUPO","ACTIVO","NOMBRE","FECHA_COMPRA","FECHA_INIC_DEP","VALOR_COMPRA",
                "VALOR_RESIDUAL","VIDA_UTIL","METODO_DEP","CTA_ACTIVO","CTA_DEPREC",
                "CTA_GASTO","RESPONSABLE","UBICACION","ESTADO","OBSERVACIONES"],
    "GETBOD":  ["PRODUCTO","NOMBRE","BODEGA","UBICACION","EXISTENCIA","COSTO_PROMEDIO",
                "COSTO_TOTAL","FECHA_CORTE"],
    "GETSAL":  ["TERCERO","NOMBRE","CUENTA","NOMBRE_CUENTA","FECHA_FACTURA",
                "FECHA_VENCIMIENTO","DIAS_VENCIDOS","VALOR_FACTURA","VALOR_ABONOS",
                "SALDO","TIPO_SALDO","CORTE_ANTERIOR"],
    "GETVEN":  ["VENDEDOR","NOMBRE","COMISION","BASE_COMISION","CUENTA","ACTIVO",
                "EMAIL","TELEFONO","OBSERVACIONES"],
    "GETCOS":  ["CENTRO","SUBCENTRO","NOMBRE","RESPONSABLE","CUENTA","ACTIVO","OBSERVACIONES"],
    "GETTBO":  ["BODEGA","NOMBRE","UBICACION","RESPONSABLE","DIRECCION","CUENTA",
                "ACTIVO","PORCENTAJE","OBSERVACIONES"],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("funcion", help="GETTER, GETMOV, PUSHTER, ...")
    ap.add_argument("--salida", required=True, help="Ruta del .xlsx a generar")
    ap.add_argument("--offline", action="store_true",
                    help="No invoca el CLI; usa estructura conocida de columnas")
    ap.add_argument("--fini"); ap.add_argument("--ffin"); ap.add_argument("--tipo")
    ap.add_argument("--tercero", nargs=2, metavar=("INI","FIN"))
    ap.add_argument("--producto",nargs=2, metavar=("INI","FIN"))
    ap.add_argument("--cuenta",  nargs=2, metavar=("INI","FIN"))
    args = ap.parse_args()

    funcion = args.funcion.upper()

    if args.offline:
        cols = COLUMNAS_CONOCIDAS.get(funcion)
        if not cols:
            print(f"ERROR: no conozco las columnas de {funcion} en modo offline.", file=sys.stderr)
            print("       Ejecuta sin --offline (requiere SIIGO instalado) o consulta", file=sys.stderr)
            print("       references/functions-catalog.md para ver la estructura de params.", file=sys.stderr)
            sys.exit(2)
        try:
            from openpyxl import Workbook
        except ImportError:
            print("ERROR: openpyxl no instalado. pip install openpyxl", file=sys.stderr)
            sys.exit(3)
        wb = Workbook()
        ws = wb.active
        ws.title = funcion
        for i, c in enumerate(cols, start=1):
            ws.cell(row=1, column=i, value=c)
        Path(args.salida).parent.mkdir(parents=True, exist_ok=True)
        wb.save(args.salida)
        print(f"Plantilla offline generada: {args.salida} ({len(cols)} columnas)")
        return 0

    # Modo online: invocar CLI con ConDatos=N
    try:
        from excel_siigo import run, Config
    except ImportError:
        sys.path.insert(0, str(Path(__file__).parent))
        from excel_siigo import run, Config

    params = ["N"]  # ConDatos=N = sólo encabezados
    if args.fini:    params.append(args.fini)
    if args.ffin:    params.append(args.ffin)
    if args.tipo:    params.append(args.tipo)
    if args.tercero: params.extend(args.tercero)
    if args.producto:params.extend(args.producto)
    if args.cuenta:  params.extend(args.cuenta)
    # El archivo de salida SIEMPRE va al final en el manual
    params.append(args.salida)

    cfg = Config.from_env()
    result = run(funcion, params=params, config=cfg, output_file=args.salida, confirm_destructive=True)
    print(result.to_json())
    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(main())
