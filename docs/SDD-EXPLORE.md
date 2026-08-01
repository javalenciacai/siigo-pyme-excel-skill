# SDD Explore — Análisis del CLI ExcelSIIGO.exe

Fecha: 2026-08-01
Fuente primaria: `C:\Siigo\ExcelSIIGO-Ayuda.LOG` (961 líneas, 51 KB).
Binario analizado: `C:\Siigo\EXCELSIIGO.exe` (120 KB, PE32 Windows).
Fuentes secundarias (no accesibles en este entorno, registradas como referencias):
- https://portaldeclientes.siigo.com/
- https://siigopyme2.portaldeclientes.siigo.com/

## 1. ¿Qué es ExcelSIIGO.exe?

Es un **CLI de Windows** distribuido por SIIGO S.A.S. (Colombia) junto con
SIIGO Pyme (software contable/ERP on-premise para PyMEs). Su propósito es
**intercambiar datos entre SIIGO Pyme y archivos Excel** (.xlsx) usando
funciones de **extracción (GET*)** e **importación (PUSH*)**.

Sirve como puente nativo de integración para automatizar:

- Migración inicial de datos desde/hacia SIIGO Pyme.
- Cargas masivas de maestros (terceros, productos, cuentas, bodegas, etc.).
- Extracción periódica de movimientos contables, saldos de bodega, saldos de
  cartera, etc., para alimentar BI, reportería o integraciones con otros
  sistemas (ej. Reportia).
- Intercambio de documentos extracontables (cotizaciones, órdenes de
  pedido/compra).

## 2. Forma de uso

Sintaxis canónica (de la línea 5 del .LOG):

```
ExcelSIIGO RutaEmpresa Año Funcion Norma Usuario Clave NombreLog [params...]
```

| Parámetro     | Largo    | Significado                                           | Ejemplo              |
|---------------|----------|-------------------------------------------------------|----------------------|
| RutaEmpresa   | 11 chars | Ruta absoluta a la carpeta de la empresa (termina \\) | `C:\SIIWI01\`        |
| Año           | 4 díbits | Año de proceso                                        | `2018`               |
| Funcion       | 10 chars | GET* / PUSH* (ver §3)                                 | `GETMOV`             |
| Norma         | 1 char   | `L` (Local) o `N` (NIIF)                              | `L`                  |
| Usuario       | 8 chars  | Usuario SIIGO que ejecuta                             | `Usuario`            |
| Clave         | 8 chars  | Contraseña del usuario                                | `Clave`              |
| NombreLog     | 50 chars | Ruta del archivo LOG a generar                        | `C:\SIIWI01\LOGS\ExcelSiigo.log` |

Si `RutaEmpresa` no está instalada aparece `070 Empresa no se encuentra instalada`.

## 3. Catálogo de funciones (46 funciones documentadas)

### 3.1 Movimiento Contable

- **GETMOV** — Extraer movimiento contable.
  Params: ConDatos, FIni (MMDD), FFin (MMDD), TipoComp (*, F, ...), CompIni, CompFin,
  NroIni, NroFin, ArchivoXLSX, ModeloBasico (S/N), CtaIni, CtaFin, ProdIni, ProdFin.
- **PUSHMOV** — Importar movimiento contable.
  Params: ArchivoXLSX, ModificaDocumentos (S/N), FacturaBasica (S/N), LogErrores.
- **GETMVT** — Igual que GETMOV pero desde el módulo de Cajero.
- (No hay PUSHMVT documentado en el .LOG; verificar en versión real.)

### 3.2 Terceros

- **GETTER** — Extraer terceros. Params: ConDatos, TerceroIni, TerceroFin, XLSX, Clasificacion (T/C/P/O), FecAperturaIni (YYYYMMDD), FecAperturaFin.
- **PUSHTER** — Importar terceros. Params: XLSX, LogErrores.

### 3.3 Activos Fijos

- **GETGRA** / **PUSHGRA** — Grupos de activos (rango 4 dígitos).
- **GETACT** / **PUSHACT** — Activos (rango 9 dígitos).

### 3.4 Documentos Extracontables

- **GETEXT** — Extraer (Tipos: * = Todos, Z=Orden de Pedido, Y=Orden de Compra, V=Cotización).
- **PUSHEXT** — Importar.

### 3.5 Inventarios

- **GETLIN** / **PUSHLIN** — Líneas y grupos (formato 7d: 3 línea + 4 grupo).
- **GETINV** / **PUSHINV** — Productos (13d: 3+4+6).
- **GETLIS** / **PUSHLIS** — Listas de precio por producto + CódigoMoneda (2d).
- **GETKIT** / **PUSHKIT** — Formulación de productos (Kits).
- **GETPRE** / **PUSHPRE** — Presupuesto de venta.
- **GETBOD** — Saldos por bodega (Prod, Bodega, MesCorte).
- **GETBOP** — Saldos por bodega para clasificaciones.
- **GETBODM** / **PUSHBODM** — Máx/Mín por bodega.

### 3.6 Cartera

- **GETSAL** — Saldos CxC o CxP. Params: TerceroIni/Fin, CtaIni/Fin, SaldoCtas (*, C, P), XLSX, ACorteAnterior (S/N), FechaCorte (MMDD).

### 3.7 Contabilidad

- **GETCTA** / **PUSHCTA** — Cuentas contables (10 dígitos).
- **GETMUL** / **PUSHMUL** — Definición de cuentas para múltiples retenciones.
- **GETICA** / **PUSHICA** — Actividades económicas ICA (5 dígitos).

### 3.8 Maestros generales

- **GETCIU** — Países y ciudades.
- **GETVEN** / **PUSHVEN** — Vendedores.
- **GETCOS** / **PUSHCOS** — Centros y sub-centros de costo.
- **GETTBO** / **PUSHTBO** — Bodegas y ubicaciones.

### 3.9 Seriales

- **GETSRL** — Maestro de seriales (Serial 25 chars, Estado D/N/T).
- **GETMSRL** — Movimiento de seriales.
- **GETBSRL** — Seriales por bodega.

### 3.10 Nómina / RR.HH.

- **GETHN** — Histórico de novedades (TipoNovedad: CC, VA, SU + Modelo).
- **GETEMPL** / **PUSHEMPL** — Empleados.
- **GETNOV** — Novedades de nómina (Cesantías, Licencias, Primas, Embargos, Préstamos, Ahorros, Incapacidad, Vacaciones, Generales).

### 3.11 Informes

- **GETINF** — Informes. TipoInforme:
  - `B`  → Balance de comprobación por tercero.
  - `BCC` → Balance de comprobación por cuenta.

## 4. Convenciones y restricciones detectadas

- **Fechas**: 2 formatos. `MMDD` (4d) para movimientos/saldos, `YYYYMMDD` (8d) para terceros/empleados.
- **Rangos numéricos fijos** por tipo de maestro (10d, 13d, 4d, 5d, 3d, 7d). El CLI **no valida** rangos fuera de los indicados y los trata como strings.
- **Códigos de movimiento**:
  - `*` = Todos los tipos de comprobante.
  - `F` = Facturas (en GETMOV); en GETEXT también Z, Y, V.
  - `L` = Norma Local, `N` = NIIF.
- **Nros de comprobante**: siempre 11 dígitos, zero-padded.
- **Modelo Básico (S/N)**: aplicable a GETMOV/PUSHMOV. Documenta 7 limitaciones
  (sin múltiples formas de pago, sin moneda extranjera, sin seriales, sin AIU,
  sin clasificaciones, sin activos fijos, sólo productos en interface).
- **ConDatos**: `N` = sólo encabezados del XLSX plantilla, `S` = datos reales.
- **Salida de PUSH***: el resultado queda en la carpeta `TEMP` de la empresa.
- **Errores**: las funciones PUSH* aceptan un parámetro `Ruta\nombrelogerrores`
  donde se deposita el XLSX con los registros rechazados.
- **Ruta por defecto del archivo de salida**: si no se especifica ruta completa,
  el archivo queda en `C:\Users\<usuario>\Documents\` (línea 961 del .LOG).

## 5. Forma del ejecutable y entorno

- Es un **PE32 Windows** (no .NET nativo aparente; binario Win32 + DLLs
  auxiliares como `InterISiigo.dll` en `C:\Siigo\ISIIGO\`).
- Requiere **SIIGO Pyme instalado localmente** con la empresa ya creada.
- Lee/escribe archivos **.xlsx** (Office Open XML).
- **No es multiplataforma**: solo Windows. Para invocarlo desde un script
  multiplataforma se debe ejecutar vía Wine o invocación remota (RDP/PSExec).
- **Licencia**: requiere que la empresa tenga licencia SIIGO vigente; el CLI
  internamente valida vía `CtrlSIIGOLic.gnt` y `Actualizador.exe`.

## 6. Casos de uso del skill (lo que un agente debe poder hacer)

1. **Inventariar maestros**: extraer productos, terceros, cuentas, bodegas
   para sincronizar con sistemas externos.
2. **Carga masiva**: preparar un .xlsx a partir de datos de otra fuente y
   ejecutar PUSHTER, PUSHINV, PUSHCTA, PUSHACT, etc.
3. **Reportería contable**: extraer movimientos (GETMOV) y saldos (GETSAL,
   GETINF) en periodos específicos.
4. **Migración**: extraer todo (GET*) de una empresa origen y luego
   reimportar (PUSH*) en una empresa destino.

## 7. Riesgos y gotchas

- El CLI imprime errores a **stdout/stderr sin código de salida consistente**;
  el .LOG es la fuente de verdad del resultado.
- Las rutas con espacios requieren estar entre comillas.
- `EXCELSIIGO.CFG` está vacío por defecto (no usar como configuración).
- Los archivos `CtrlSIIGOLV*.gnt` y `Actualizador.exe` validan licencia; sin
  licencia activa, el CLI puede fallar en mitad de una operación.
- La codificación del .LOG es **Windows-1252** (caracteres acentuados
  aparecen como `A�o`, `Funci�n`, etc.). No es UTF-8.
- El ejecutable devuelve `070 Empresa no se encuentra instalada` si la
  RutaEmpresa no apunta a una empresa SIIGO válida.

## 8. Información que NO se encontró en el .LOG (declarada como gap)

- No hay docs de PUSHMVT.
- No hay docs de PUSHSRL/PUSHMSRL/PUSHBSRL (sólo GET*).
- No hay docs de PUSHNOV.
- No hay GET de Nómina conceptos variables, sólo GETHN.
- Códigos de error completos (sólo se conoce el 070).
- Comportamiento exacto cuando hay licencia vencida o empresa en uso.

Estos gaps se documentan en la sección "Limitaciones conocidas" del SKILL.md.

## 9. Conclusión del Explore

El CLI es **simple, determinista, sincrónico y bien documentado** en su archivo
de ayuda. La mejor estrategia para un skill es:

1. Empaquetar toda la documentación como **referencia** (no cargar en contexto
   por defecto; cargable bajo demanda).
2. Exponer **wrappers Bash** y **PowerShell** que invoquen el .exe con la
   sintaxis correcta, validen rutas y parseen el .LOG resultante.
3. Detectar errores típicos (empresa no instalada, archivo de entrada
   inexistente, licencia, codificación) y devolver mensajes claros al agente.
4. Proveer **plantillas .xlsx vacías** (ConDatos=N) para cada GET* y
   documentación de las columnas esperadas para los PUSH*.
5. Marcar **destructivo** cualquier PUSH* y pedir confirmación explícita
   (importar datos en SIIGO es destructivo en la base de la empresa).
