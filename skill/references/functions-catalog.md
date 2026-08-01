# Catálogo de funciones ExcelSIIGO.exe

46 funciones documentadas en `excel-siigo-help.md`. Convención:

- **GET*** = extraer datos de SIIGO → archivo .xlsx.
- **PUSH*** = importar archivo .xlsx → SIIGO.
- Todas requieren: `RutaEmpresa Año Funcion Norma Usuario Clave NombreLog`.
- Los rangos numéricos (cuentas 10d, productos 13d, bodegas 4d, etc.) son
  **estrictos**: rellena con ceros a la izquierda.

## Movimiento contable

| Función   | Tipo | Params específicos (en orden)                                                                                                  |
|-----------|------|--------------------------------------------------------------------------------------------------------------------------------|
| GETMOV    | GET  | ConDatos, FIni(MMDD), FFin(MMDD), TipoComp(*/F/...), CompIni(3d), CompFin(3d), NroIni(11d), NroFin(11d), XLSX, ModeloBasico(S/N), CtaIni(10d), CtaFin(10d), ProdIni(13d), ProdFin(13d) |
| PUSHMOV   | PUSH | XLSX, ModificaDocumentos(S/N), FacturaBasica(S/N), LogErrores                                                                  |
| GETMVT    | GET  | Igual que GETMOV (Cajero)                                                                                                      |
| PUSHMVT   | PUSH | (NO documentado en manual — verificar versión)                                                                                 |

## Terceros

| Función  | Tipo | Params específicos                                                            |
|----------|------|-------------------------------------------------------------------------------|
| GETTER   | GET  | ConDatos, TerceroIni(13d), TerceroFin(13d), XLSX, Clasificacion(T/C/P/O), FecAperturaIni(YYYYMMDD), FecAperturaFin(YYYYMMDD) |
| PUSHTER  | PUSH | XLSX, LogErrores                                                              |

## Activos fijos

| Función  | Tipo | Params específicos                                  |
|----------|------|-----------------------------------------------------|
| GETGRA   | GET  | ConDatos, GrupoIni(4d), GrupoFin(4d), XLSX          |
| PUSHGRA  | PUSH | XLSX, LogErrores                                    |
| GETACT   | GET  | ConDatos, ActivoIni(9d), ActivoFin(9d), XLSX        |
| PUSHACT  | PUSH | XLSX, LogErrores                                    |

## Documentos extracontables

| Función  | Tipo | Params específicos                                                                                  |
|----------|------|-----------------------------------------------------------------------------------------------------|
| GETEXT   | GET  | ConDatos, FIni(MMDD), FFin(MMDD), TipoComp(*/Z/Y/V), CompIni(3d), CompFin(3d), NroIni(11d), NroFin(11d), XLSX |
| PUSHEXT  | PUSH | XLSX, LogErrores                                                                                    |

Tipos: `*`=Todos, `Z`=Orden de Pedido, `Y`=Orden de Compra, `V`=Cotización.

## Inventarios

| Función  | Tipo | Params específicos                                                                  |
|----------|------|-------------------------------------------------------------------------------------|
| GETLIN   | GET  | ConDatos, LineaGrupoIni(7d = 3 línea + 4 grupo), LineaGrupoFin(7d), XLSX            |
| PUSHLIN  | PUSH | XLSX, LogErrores                                                                    |
| GETINV   | GET  | ConDatos, ProdIni(13d = 3+4+6), ProdFin(13d), XLSX                                  |
| PUSHINV  | PUSH | XLSX, LogErrores                                                                    |
| GETLIS   | GET  | ConDatos, ProdIni(13d), ProdFin(13d), XLSX, CodigoMoneda(2d)                        |
| PUSHLIS  | PUSH | XLSX, LogErrores                                                                    |
| GETKIT   | GET  | ConDatos, ProdIni(13d), ProdFin(13d), XLSX                                          |
| PUSHKIT  | PUSH | XLSX, LogErrores                                                                    |
| GETPRE   | GET  | ConDatos, ProdIni(13d), ProdFin(13d), XLSX                                          |
| PUSHPRE  | PUSH | XLSX, LogErrores                                                                    |
| GETBOD   | GET  | ConDatos, ProdIni(13d), ProdFin(13d), BodegaIni(4d), BodegaFin(4d), MesCorte(2d), XLSX |
| GETBOP   | GET  | Idem GETBOD (para clasificaciones)                                                  |
| GETBODM  | GET  | ConDatos, ProdIni(13d), ProdFin(13d), BodegaIni(4d), BodegaFin(4d), XLSX            |
| PUSHBODM | PUSH | XLSX, LogErrores                                                                    |

## Cartera

| Función  | Tipo | Params específicos                                                                                  |
|----------|------|-----------------------------------------------------------------------------------------------------|
| GETSAL   | GET  | ConDatos, TerceroIni(13d), TerceroFin(13d), CtaIni(10d), CtaFin(10d), SaldoCtas(*/C/P), XLSX, ACorteAnterior(S/N), FechaCorte(MMDD) |

Tipos: `*`=Todos, `C`=Cuentas por Cobrar, `P`=Cuentas por Pagar.

## Contabilidad

| Función  | Tipo | Params específicos                                       |
|----------|------|----------------------------------------------------------|
| GETCTA   | GET  | ConDatos, CtaIni(10d), CtaFin(10d), XLSX                 |
| PUSHCTA  | PUSH | XLSX, LogErrores                                         |
| GETMUL   | GET  | ConDatos, CtaPrincipalIni(10d), CtaPrincipalFin(10d), XLSX |
| PUSHMUL  | PUSH | XLSX, LogErrores                                         |
| GETICA   | GET  | ConDatos, ActEconIni(5d), ActEconFin(5d), XLSX           |
| PUSHICA  | PUSH | XLSX, LogErrores                                         |

## Maestros generales

| Función  | Tipo | Params específicos                                                                                  |
|----------|------|-----------------------------------------------------------------------------------------------------|
| GETCIU   | GET  | ConDatos, PaisIni(3d), PaisFin(3d), CiudadIni(4d), CiudadFin(4d), XLSX                              |
| GETVEN   | GET  | ConDatos, VendedorIni(4d), VendedorFin(4d), XLSX                                                    |
| PUSHVEN  | PUSH | XLSX, LogErrores                                                                                    |
| GETCOS   | GET  | ConDatos, CtroCostoIni(4d), CtroCostoFin(4d), SubCtroCostoIni(3d), SubCtroCostoFin(3d), XLSX        |
| PUSHCOS  | PUSH | XLSX, LogErrores                                                                                    |
| GETTBO   | GET  | ConDatos, BodegaIni(4d), BodegaFin(4d), UbicacionIni(3d), UbicacionFin(3d), XLSX                    |
| PUSHTBO  | PUSH | XLSX, LogErrores                                                                                    |

## Seriales

| Función  | Tipo | Params específicos                                                                                                                                       |
|----------|------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| GETSRL   | GET  | ConDatos, SerialIni(25c), SerialFin(25c), ProdIni(13d), ProdFin(13d), Estado(D/N/T), XLSX                                                                |
| GETMSRL  | GET  | ConDatos, FIni(MMDD), FFin(MMDD), TipoComp, CompIni(3d), CompFin(3d), NroIni(11d), NroFin(11d), ProdIni(13d), ProdFin(13d), TerceroIni(13d), TerceroFin(13d), XLSX |
| GETBSRL  | GET  | ConDatos, SerialIni(25c), SerialFin(25c), ProdIni(13d), ProdFin(13d), BodegaIni(4d), BodegaFin(4d), Estado(D/N/T), XLSX                                  |

> **Nota**: PUSHSRL / PUSHMSRL / PUSHBSRL no aparecen en el manual. Verificar
> con la versión instalada de `EXCELSIIGO.exe`.

## Nómina / RR.HH.

| Función  | Tipo | Params específicos                                                                                                                                       |
|----------|------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| GETHN    | GET  | TipoNovedad(CC/VA/SU), Modelo, CtroCostoIni(4d), CtroCostoFin(4d), SubCtroCostoIni(3d), SubCtroCostoFin(3d), TerceroIni(13d), TerceroFin(13d), FIni(MMDD), FFin(MMDD), CargoIni(4d), CargoFin(4d), XLSX |
| GETEMPL  | GET  | ConDatos, EmpleadoIni(13d), EmpleadoFin(13d), FecAperturaIni(YYYYMMDD), FecAperturaFin(YYYYMMDD), IncluyeRetirados(S/N), XLSX                              |
| PUSHEMPL | PUSH | XLSX, LogErrores                                                                                                                                         |
| GETNOV   | GET  | TipoNovedad(C/L/P/E/R/A/I/V/G), XLSX                                                                                                                    |

Tipos GETHN: `CC`=Cambio centro costo, `VA`=Vacaciones, `SU`=Cambio sueldo.
Tipos GETNOV: `C`=Cesantías, `L`=Licencias, `P`=Anticipo Primas, `E`=Embargos,
`R`=Préstamos, `A`=Ahorros, `I`=Incapacidad, `V`=Vacaciones, `G`=Generales.

## Informes

| Función  | Tipo | Params específicos                                                                                  |
|----------|------|-----------------------------------------------------------------------------------------------------|
| GETINF   | GET  | TipoInforme, NitIni(13d), NitFin(13d), MesIni(2d), MesFin(2d), XLSX                                |

Tipos:
- `B`  → Balance de comprobación por tercero.
- `BCC` → Balance de comprobación por cuenta.

> ⚠️ El manual lista `TerceroIni`/`TerceroFin` para `B` y `CuentaIni`/`CuentaFin`
> para `BCC` con el mismo nombre de parámetro. El wrapper detecta el tipo y
> pasa los params correctos.

## Reglas generales

1. `ConDatos = N` genera el .xlsx con sólo encabezados (plantilla).
2. `ConDatos = S` genera el .xlsx con datos reales.
3. Todos los `PUSH*` depositan el resultado de la importación en la carpeta
   `TEMP` de la empresa correspondiente.
4. El log de errores de los `PUSH*` es un .xlsx en la ruta `LogErrores`.
5. Si no se especifica ruta completa en `XLSX`, el archivo queda en
   `C:\Users\<usuario>\Documents\`.
