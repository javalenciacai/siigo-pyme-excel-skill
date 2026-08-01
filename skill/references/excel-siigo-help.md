---
title: Manual oficial ExcelSIIGO.exe
source: C:\Siigo\ExcelSIIGO-Ayuda.LOG
encoding_origen: Windows-1252 (cp1252)
encoding_destino: UTF-8
nota: Copia del manual que el CLI imprime cuando se invoca sin empresa o con ayuda. Mantener sincronizado con la versión instalada de EXCELSIIGO.exe.
---

# Manual oficial — ExcelSIIGO.exe

> Documento de referencia. NO cargar en contexto por defecto; consultar
> bajo demanda desde SKILL.md. El agente debe preferir los wrappers de
> `scripts/` antes que construir comandos a mano.

## Sintaxis general

001 Parámetros Incorrectos

Sintaxis ExcelSIIGO:

ExcelSIIGO RutaEmpresa Año Funcion Norma Usuario Clave NombreLog

RutaEmpresa:  11 Caracteres      Ej: C:\SIIWI01\
Año:  4 dígitos, año de proceso en Siigo    Ej: 2016
Función: 10 Caracteres, función a ejecutar Ej: GETMOV
Norma: 1 Carácter, norma de la que se extraerá la información (Local/NIIF) Ej: L
Usuario: 8 Caracteres, Usuario de Siigo que ejecuta el proceso
Clave: 8 Caracteres, Clave del Usuario de Siigo que ejecuta el proceso
NombreLog: 50 Caracteres, Nombre Archivo LOG a generar con el resultado de la ejecución por defecto se genera ExcelSiigo.log

Ejemplo:
ExcelSIIGO C:\SIIWI01\ 2018 GETMOV L Usuario Clave ExcelSiigo.log


******************************************************************************************************************************************************
                   LISTA DE FUNCIONES
******************************************************************************************************************************************************

======================================================================================================================================================
Interfaces Movimiento Contable
======================================================================================================================================================

GETMOV :Extraer Movimiento Contable

ExcelSIIGO RutaEmpresa Año GETMOV Norma Usuario Clave NombreLog ConDatos FechaInicial FechaFinal TipoComprobante CodigoComprobanteInicial CodigoComprobanteFinal NroInicial NroFinal NombreArchivoExcelSalida ModeloBásico CuentaInicial CuentaFinal ProductoInicial ProductoFinal

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
FechaInicial: 4 dígitos, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 0517
FechaFinal: 4 dígitos, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 0530
TipoComprobante: 1 Caracter, * = Todos, F=Facturas,etc.   Ej: F
CodigoComprobanteInicial: 3 dígitos, Código comprobante a Exportar   Ej: 001
CodigoComprobanteFinal: 3 dígitos, Código comprobante a Exportar   Ej: 002
NroInicial: 11 dígitos, Número comprobante inicial a exportar   Ej: 00000000001
NroFinal: 11 dígitos, Número comprobante Final a exportar   Ej: 99999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\MovimientoContable.xlsx
ModeloBásico: 1 caracter, Digite N = Exporta toda la información Solicitada.
CuentaInicial: 10 dígitos Ej: 1105050100
CuentaFinal: 10 dígitos Ej: 1110050100
ProductoInicial: 13 dígitos Ej: 0020001000523
ProductoFinal: 13 dígitos Ej: 0020001999999

IMPORTANTE: Tener en cuenta si desea exportar un documento básico: ModeloBásico = S
Este proceso genera un modelo para exportar movimiento contable
con datos Básicos obligatorios, que facilitaran la contabilización del documento.
Las condiciones del modelo BÁSICO son:
1. No Maneja múltiples formas de pago.
2. Solo digitar productos en la interface.
3. No se contemplan Activos Fijos.
4. No Maneja Moneda Extranjera.
5. No aplica para manejo de AIU
6. No contempla seriales.
7. No contempla clasificaciones.


Ejemplo GETMOV:

ExcelSIIGO C:\SIIWI01\ 2018 GETMOV L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0517 0531 F 001 002 00000000001 99999999999 C:\SIIWI01\MovimientoContable.xlsx N 1105050100 1110050100 0020001000523 0020001999999
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHMOV :Importar Movimiento Contable a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHMOV Norma Usuario Clave NombreLog NombreArchivoExcelEntrada ModificaDocumentos FacturaBásica Ruta\nombrelogerrores
NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\MovimientoContable.xlsx
ModificaDocumentos: S - Reemplaza documentos ya existentes o N - No permite modificar documentos
FacturaBásica: S - Genera la factura a partir del producto facturado o N - Sube el documento como está en excel
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE: Tener en cuenta si desea importar un documento básico: ModeloBásico = S
Este proceso genera un modelo para importar movimiento contable
con datos Básicos obligatorios, que facilitaran la contabilización del documento.
Las condiciones del modelo BÁSICO son:
1. No Maneja múltiples formas de pago.
2. Solo digitar productos en la interface.
3. No se contemplan Activos Fijos.
4. No Maneja Moneda Extranjera.
5. No aplica para manejo de AIU
6. No contempla seriales.
7. No contempla clasificaciones.
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.

Ejemplo PUSHMOV:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHMOV L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\MovimientoContable.xlsx N N C:\SIIWI01\LOGS\ErrorMov.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETMVT :Extraer Movimiento Contable de Cajero

ExcelSIIGO RutaEmpresa Año GETMVT Norma Usuario Clave NombreLog ConDatos FechaInicial FechaFinal TipoComprobante CodigoComprobanteInicial CodigoComprobanteFinal NroInicial NroFinal NombreArchivoExcelSalida ModeloBásico CuentaInicial CuentaFinal ProductoInicial ProductoFinal

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
FechaInicial: 4 dígitos, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 0517
FechaFinal: 4 dígitos, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 0530
TipoComprobante: 1 Caracter, * = Todos, F=Facturas,etc.   Ej: F
CodigoComprobanteInicial: 3 dígitos, Código comprobante a Exportar   Ej: 001
CodigoComprobanteFinal: 3 dígitos, Código comprobante a Exportar   Ej: 002
NroInicial: 11 dígitos, Número comprobante inicial a exportar   Ej: 00000000001
NroFinal: 11 dígitos, Número comprobante Final a exportar   Ej: 99999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\MovimientoContableCajero.xlsx
ModeloBásico: 1 caracter, Digite N = Exporta toda la información Solicitada.
CuentaInicial: 10 dígitos Ej: 1105050100
CuentaFinal: 10 dígitos Ej: 1110050100
ProductoInicial: 13 dígitos Ej: 0020001000523
ProductoFinal: 13 dígitos Ej: 0020001999999



Ejemplo GETMVT:

ExcelSIIGO C:\SIIWI01\ 2018 GETMVT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0517 0531 F 001 002 00000000001 99999999999 C:\SIIWI01\MovimientoContableCajero.xlsx N 1105050100 1110050100 0020001000523 0020001999999
------------------------------------------------------------------------------------------------------------------------------------------------------


======================================================================================================================================================
Interfaces Terceros
======================================================================================================================================================

GETTER :Extraer Terceros

ExcelSIIGO RutaEmpresa Año GETTER Norma Usuario Clave NombreLog ConDatos TerceroInicial TerceroFinal NombreArchivoExcelSalida Clasificacion DesdeFechaApertura HastaFechaApertura

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
TerceroInicial: 13 dígitos Ej: 1
TerceroFinal: 13 dígitos Ej: 9999999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Terceros.xlsx
Clasificación: 1 Carácter, T = Todos, C = Clientes, P = Proveedores, O = Otros Ej: T
DesdeFechaApertura: 8 dígitos Ej: 0
HastaFechaApertura: 8 dígitos Ej: 99999999


Ejemplo GETTER:

ExcelSIIGO C:\SIIWI01\ 2018 GETTER L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1 9999999999999 C:\SIIWI01\Terceros.xlsx T 20190101 20191231
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHTER :Importar Terceros a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHTER Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Terceros.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHTER:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHTER L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Terceros.xlsx C:\SIIWI01\LOGS\ErrorTer.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces Activos Fijos
======================================================================================================================================================

GETGRA :Extraer Grupos de Activos

ExcelSIIGO RutaEmpresa Año GETGRA Norma Usuario Clave NombreLog ConDatos GrupoInicial GrupoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
GrupoInicial: 4 dígitos Ej: 1
GrupoFinal: 4 dígitos Ej: 9999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\GruposActivos.xlsx


Ejemplo GETGRA:

ExcelSIIGO C:\SIIWI01\ 2018 GETGRA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1 9999 C:\SIIWI01\GruposActivos.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHGRA :Importar Grupos de Activos a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHGRA Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\GruposActivos.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHGRA:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHGRA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\GruposActivos.xlsx C:\SIIWI01\LOGS\ErrorGrA.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETACT :Extraer Activos

ExcelSIIGO RutaEmpresa Año GETACT Norma Usuario Clave NombreLog ConDatos ActivoInicial ActivoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ActivoInicial: 9 dígitos Ej: 1
ActivoFinal: 9 dígitos Ej: 999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Activos.xlsx


Ejemplo GETACT:

ExcelSIIGO C:\SIIWI01\ 2018 GETACT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1 999999999 C:\SIIWI01\Activos.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHACT :Importar Activos a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHACT Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Activos.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHACT:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHACT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Activos.xlsx C:\SIIWI01\LOGS\ErrorAct.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces de Documentos ExtraContables
======================================================================================================================================================

GETEXT :Extraer Documentos ExtraContables

ExcelSIIGO RutaEmpresa Año GETEXT Norma Usuario Clave NombreLog ConDatos FechaInicial FechaFinal TipoComprobante CodigoComprobanteInicial CodigoComprobanteFinal NroInicial NroFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
FechaInicial: 4 dígitos, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 0517
FechaFinal: 4 dígitos, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 0530
TipoComprobante: 1 Caracter, * = Todos, Z=Orden de Pedido, Y=Orden de Compra, V=Cotización.   Ej: V
CodigoComprobanteInicial: 3 dígitos, Código comprobante a Exportar   Ej: 001
CodigoComprobanteFinal: 3 dígitos, Código comprobante a Exportar   Ej: 002
NroInicial: 11 dígitos, Número comprobante inicial a exportar   Ej: 00000000001
NroFinal: 11 dígitos, Número comprobante Final a exportar   Ej: 99999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\DocExtraContable.xlsx


Ejemplo GETEXT:

ExcelSIIGO C:\SIIWI01\ 2018 GETEXT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0417 0431 V 001 001 00000000001 99999999999 C:\SIIWI01\DocExtraContable.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHEXT :Importar Documentos ExtraContables a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHEXT Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\DocExtraContable.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHEXT:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHEXT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\DocExtraContable.xlsx C:\SIIWI01\LOGS\ErrorExtracontables.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces Inventarios
======================================================================================================================================================

GETLIN :Extraer Líneas y grupos de Inventarios

ExcelSIIGO RutaEmpresa Año GETLIN Norma Usuario Clave NombreLog ConDatos LineaGrupoInicial LineaGrupoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
LineaGrupoInicial: 7 dígitos Ej: 0010001
LineaGrupoFinal: 7 dígitos Ej: 9999999

--> Línea: 3 dígitos, Grupo: 4 dígitos
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\LineasGruposInv.xlsx


Ejemplo GETLIN:

ExcelSIIGO C:\SIIWI01\ 2018 GETLIN L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 10001 9999999 C:\SIIWI01\LineasGruposInv.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHLIN :Importar Líneas y grupos de inventario a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHLIN Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\LineasGruposInv.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHLIN:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHLIN L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\LineasGruposInv.xlsx C:\SIIWI01\LOGS\ErrorLinInv.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETINV :Extraer Productos de Inventarios

ExcelSIIGO RutaEmpresa Año GETINV Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999

--> Línea: 3 dígitos, Grupo: 4 dígitos, Producto: 6 dígitos
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Productos.xlsx


Ejemplo GETINV:

ExcelSIIGO C:\SIIWI01\ 2018 GETINV L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 10001000001 9999999999999 C:\SIIWI01\Productos.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHINV :Importar Productos a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHINV Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Productos.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHINV:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHINV L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Productos.xlsx C:\SIIWI01\LOGS\ErrorInventarios.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETLIS :Extraer Listas de Precio por producto

ExcelSIIGO RutaEmpresa Año GETLIS Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal NombreArchivoExcelSalida CódigoMoneda

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999

--> Línea: 3 dígitos, Grupo: 4 dígitos, Producto: 6 dígitos
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\ListasPrecio.xlsx
CódigoMoneda: 2 dígitos Ej: 00


Ejemplo GETLIS:

ExcelSIIGO C:\SIIWI01\ 2018 GETLIS L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 10001000001 9999999999999 C:\SIIWI01\ListasPrecio.xlsx 00
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHLIS :Importar Listas de Precio productos a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHLIS Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\ListasPrecio.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHLIS:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHLIS L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\ListasPrecio.xlsx C:\SIIWI01\LOGS\ErrorLis.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETKIT :Extraer Formulación de Productos (kits)

ExcelSIIGO RutaEmpresa Año GETKIT Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999

--> Línea: 3 dígitos, Grupo: 4 dígitos, Producto: 6 dígitos
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Kits.xlsx


Ejemplo GETKIT:

ExcelSIIGO C:\SIIWI01\ 2018 GETKIT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 10001000001 9999999999999 C:\SIIWI01\Kits.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHKIT :Importar Formulación de Productos (kits)

ExcelSIIGO RutaEmpresa Año PUSHKIT Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Kits.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHKIT:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHKIT L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Kits.xlsx C:\SIIWI01\LOGS\ErrorKits.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETPRE :Extraer Formulación Presupuesto de venta

ExcelSIIGO RutaEmpresa Año GETPRE Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999

--> Línea: 3 dígitos, Grupo: 4 dígitos, Producto: 6 dígitos
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\PresupuestoVta.xlsx


Ejemplo GETPRE:

ExcelSIIGO C:\SIIWI01\ 2018 GETPRE L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 10001000001 9999999999999 C:\SIIWI01\PresupuestoVta.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHPRE :Importar Formulación Presupuesto de venta

ExcelSIIGO RutaEmpresa Año PUSHPRE Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\PresupuestoVta
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHPRE:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHPRE L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\PresupuestoVta.xlsx C:\SIIWI01\LOGS\ErrorPresupuesto.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces Contabilidad
======================================================================================================================================================

GETCTA :Extraer Cuentas Contables

ExcelSIIGO RutaEmpresa Año GETCTA Norma Usuario Clave NombreLog ConDatos CuentaInicial CuentaFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
CuentaInicial: 10 dígitos Ej: 1105050100
CuentaFinal: 10 dígitos Ej: 1110050100

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\CuentasContables.xlsx


Ejemplo GETCTA:

ExcelSIIGO C:\SIIWI01\ 2018 GETCTA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1105050100 1110050500 C:\SIIWI01\CuentasContables.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHCTA :Importar Cuentas Contables a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHCTA Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\CuentasContables.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHCTA:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHCTA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\CuentasContables.xlsx C:\SIIWI01\LOGS\ErrorCuentas.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETMUL :Extraer Definición cuentas para múltiples retenciones

ExcelSIIGO RutaEmpresa Año GETMUL Norma Usuario Clave NombreLog ConDatos CuentaPrincipalInicial CuentaPrincipalFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
CuentaPrincipalInicial: 10 dígitos Ej: 1105050100
CuentaPrincipalFinal: 10 dígitos Ej: 1110050100

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\CuentasRetenciones.xlsx


Ejemplo GETMUL:

ExcelSIIGO C:\SIIWI01\ 2018 GETMUL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1105050100 1110050500 C:\SIIWI01\CuentasRetenciones.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHMUL :Importar Definición cuentas para múltiples retenciones a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHMUL Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\CuentasRetenciones.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHMUL:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHMUL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\CuentasRetenciones.xlsx C:\SIIWI01\LOGS\ErrorMultRet.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETICA :Extraer Actividades económicas (ICA)

ExcelSIIGO RutaEmpresa Año GETICA Norma Usuario Clave NombreLog ConDatos ActividadEconómicaInicial ActividadEconómicaFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ActividadEconómicaInicial: 5 dígitos Ej: 1
ActividadEconómicaFinal: 5 dígitos Ej: 99999

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Actividades.xlsx


Ejemplo GETICA:

ExcelSIIGO C:\SIIWI01\ 2018 GETICA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1 99999 C:\SIIWI01\Actividades.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHICA :Importar Actividades económicas (ICA)

ExcelSIIGO RutaEmpresa Año PUSHICA Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Actividades.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHICA:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHICA L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Actividades.xlsx C:\SIIWI01\LOGS\ErrorICA.xlsx

------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Otras Interfaces
======================================================================================================================================================

GETBOD :Extraer Saldos de Bodegas

ExcelSIIGO RutaEmpresa Año GETBOD Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal BodegaInicial BodegaFinal MesdeCorte NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal:   13 dígitos Ej: 9999999999999
BodegaInicial: 4 dígitos Ej: 0001
BodegaFinal:   4 dígitos Ej: 9999
MesdeCorte:   2 dígitos Ej: 01

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\SaldosPorBodega.xlsx


Ejemplo GETBOD:

ExcelSIIGO C:\SIIWI01\ 2018 GETBOD L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0010001000001 9999999999999 0001 9999 12 C:\SIIWI01\SaldosPorBodega.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


GETBOP :Extraer Saldos de Bodegas para Clasificaciones

ExcelSIIGO RutaEmpresa Año GETBOP Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal BodegaInicial BodegaFinal MesdeCorte NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal:   13 dígitos Ej: 9999999999999
BodegaInicial: 4 dígitos Ej: 0001
BodegaFinal:   4 dígitos Ej: 9999
MesdeCorte:   2 dígitos Ej: 01

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\SaldosClaPorBodega.xlsx


Ejemplo GETBOP:

ExcelSIIGO C:\SIIWI01\ 2018 GETBOP L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0010001000001 9999999999999 0001 9999 12 C:\SIIWI01\SaldosClaPorBodega.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


GETBODM :Extraer Máximos y Mínimos por Bodegas

ExcelSIIGO RutaEmpresa Año GETBODM Norma Usuario Clave NombreLog ConDatos ProductoInicial ProductoFinal BodegaInicial BodegaFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal:   13 dígitos Ej: 9999999999999
BodegaInicial: 4 dígitos Ej: 0001
BodegaFinal:   4 dígitos Ej: 9999

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\máximos_y_mínimos_por_bodega.xlsx

Ejemplo GETBODM:

ExcelSIIGO C:\SIIWI01\ 2018 GETBODM L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0010001000001 9999999999999 0001 9999 C:\SIIWI01\máximos_y_mínimos_por_bodega.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHBODM :Importar Máximos y Mínimos por Bodega a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHBODM Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\máximos_y_mínimos_por_bodega.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHBODM:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHBODM L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\máximos_y_mínimos_por_bodega.xlsx C:\SIIWI01\LOGS\ErrorBodMaxMin.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETSAL :Extraer Saldos Cuentas por Cobrar o Cuentas por Pagar

ExcelSIIGO RutaEmpresa Año GETSAL Norma Usuario Clave NombreLog ConDatos TerceroInicial TerceroFinal CuentaInicial CuentaFinal SaldoCuentas NombreArchivoExcelSalida ACorteAnterior FechaCorte

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
TerceroInicial: 13 dígitos Ej: 1
TerceroFinal: 13 dígitos Ej: 9999999999999
CuentaInicial: 10 dígitos Ej: 1105050100
CuentaFinal: 10 dígitos Ej: 1110050100
SaldoCuentas: 1 Caracter, * = Todos, C=Cuentas por Cobrar, P=Cuentas por Pagar.    Ej: C

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\CuentasContables.xlsx

AcorteAnterior: 1 Carácter, N = No Genera Saldos a Corte anterior, S = Si Genera Saldos a Corte anterior Ej: S
FechaCorte: 4 dígitos, 2 dígitos = Mes Corte, 2 dígitos = Dia Corte  Ej: 0530


Ejemplo GETSAL:

ExcelSIIGO C:\SIIWI01\ 2018 GETSAL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 1 9999999999999 1305050100 1305059900 C C:\SIIWI01\SaldosCartera.xlsx S 0530
------------------------------------------------------------------------------------------------------------------------------------------------------


GETCIU :Extraer información de Paises y Ciudades

ExcelSIIGO RutaEmpresa Año GETCIU Norma Usuario Clave NombreLog ConDatos PaisInicial PaisFinal CiudadInicial CiudadFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
PaisInicial: 3 digitos Ej: 001
PaisFinal: 3 digitos Ej: 002
CiudadInicial: 4 dígitos Ej: 0001
CiudadFinal: 4 dígitos Ej: 0009


NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Ciudades.xlsx


Ejemplo GETCIU:

ExcelSIIGO C:\SIIWI01\ 2022 GETCIU L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 001 999 0001 9999 C:\SIIWI01\Ciudades.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


GETVEN :Extraer informacion de vendedores

ExcelSIIGO RutaEmpresa Año GETVEN Norma Usuario Clave NombreLog ConDatos VendedorInicial VendedorFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
VendedorInicial: 4 dígitos Ej: 0001
VendedorFinal: 4 dígitos Ej: 9999

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Vendedores.xlsx


Ejemplo GETVEN:

ExcelSIIGO C:\SIIWI01\ 2018 GETVEN L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0001 9999 C:\SIIWI01\Vendedores.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHVEN :Importar Catalogo de vendedores a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHVEN Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Vendedores.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHVEN:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHVEN L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\vendedores.xlsx C:\SIIWI01\LOGS\ErrorVen.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETCOS :Extraer información de centros de costo

ExcelSIIGO RutaEmpresa Año GETCOS Norma Usuario Clave NombreLog ConDatos CentroCostoInicial CentroCostoFinal SubCentroCostoInicial SubCentroCostoFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
CentroCostoInicial: 4 dígitos Ej: 0000
CentroCostoFinal: 4 dígitos Ej: 9999
SubCentroCostoInicial: 3 dígitos Ej: 000
SubCentroCostoFinal: 3 dígitos Ej: 999

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\CentroCostos.xlsx


Ejemplo GETCOS:

ExcelSIIGO C:\SIIWI01\ 2018 GETCOS L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0000 9999 000 999 C:\SIIWI01\CentroCostos.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHCOS :Importar Catalogo de centros de costo a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHCOS Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\CentroCostos.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHCOS:

ExcelSIIGO C:\SIIWI01\ 2018 PUSHCOS L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\CentroCostos.xlsx C:\SIIWI01\LOGS\ErrorCos.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

GETTBO :Extraer información de Bodegas

ExcelSIIGO RutaEmpresa Año GETTBO Norma Usuario Clave NombreLog ConDatos BodegaInicial BodegaFinal UbicaciónInicial UbicaciónFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
BodegaInicial: 4 dígitos Ej: 0000
BodegaFinal: 4 dígitos Ej: 9999
UbicaciónInicial: 3 dígitos Ej: 000
UbicaciónFinal: 3 dígitos Ej: 999

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\Bodegas.xlsx


Ejemplo GETTBO:

ExcelSIIGO C:\SIIWI01\ 2022 GETTBO L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0000 9999 000 999 C:\SIIWI01\Bodegas.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHTBO :Importar Catalogo de bodegas a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHTBO Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Bodegas.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHTBO:

ExcelSIIGO C:\SIIWI01\ 2022 PUSHTBO L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Bodegas.xlsx C:\SIIWI01\LOGS\ErrorBodegas.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces de Seriales
======================================================================================================================================================

GETSRL :Extraer Maestro de Seriales

ExcelSIIGO RutaEmpresa Año GETSRL Norma Usuario Clave NombreLog ConDatos SerialInicial SerialFinal ProductoInicial ProductoFinal Estado NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
SerialInicial: 25 caracteres Ej: *
SerialFinal: 25 caracteres Ej: zzzzzzzzzzzzzzzzzzzzzzzzz
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999
Estado: 1 dígitos, D = Disponible, N = No disponible, T = Todos Ej: T

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\MaestroSeriales.xlsx


Ejemplo GETSRL:

ExcelSIIGO C:\SIIWI01\ 2018 GETSRL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S * zzzzzzzzzzzzzzzzzzzzzzzzz0010001000001 9999999999999 T C:\SIIWI01\MaestroSeriales.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


GETMSRL :Extraer Movimiento de Seriales

ExcelSIIGO RutaEmpresa Año GETMSRL Norma Usuario Clave NombreLog ConDatos FechaInicial FechaFinal TipoComprobante CodigoComprobanteInicial CodigoComprobanteFinal NroInicial NroFinal ProductoInicial ProductoFinal TerceroInicial TerceroFinal NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
FechaInicial: 4 dígitos, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 0501
FechaFinal: 4 dígitos, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 0530
TipoComprobante: 1 Caracter, * = Todos, F=Facturas,etc.   Ej: F
CodigoComprobanteInicial: 3 dígitos, Código comprobante a Exportar   Ej: 001
CodigoComprobanteFinal: 3 dígitos, Código comprobante a Exportar   Ej: 002
NroInicial: 11 dígitos, Número comprobante inicial a exportar   Ej: 00000000001
NroFinal: 11 dígitos, Número comprobante Final a exportar   Ej: 99999999999
ProductoInicial: 13 dígitos, Producto inicial a exportar   Ej: 0020001000523
ProductoFinal: 13 dígitos, Producto Final a exportar   Ej: 0020001999999
TerceroInicial: 13 dígitos Ej: 1
TerceroFinal: 13 dígitos Ej: 9999999999999
NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\MovimientoSeriales.xlsx



Ejemplo GETMSRL:

ExcelSIIGO C:\SIIWI01\ 2018 GETMSRL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S 0501 0531 F 001 002 00000000001 99999999999  0020001000523 0020001999999 1 9999999999999 C:\SIIWI01\MovimientoSeriales.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


GETBSRL :Extraer Seriales por Bodega

ExcelSIIGO RutaEmpresa Año GETBSRL Norma Usuario Clave NombreLog ConDatos SerialInicial SerialFinal ProductoInicial ProductoFinal BodegaInicial BodegaFinal Estado NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
SerialInicial: 25 caracteres Ej: *
SerialFinal: 25 caracteres Ej: zzzzzzzzzzzzzzzzzzzzzzzzz
ProductoInicial: 13 dígitos Ej: 0010001000001
ProductoFinal: 13 dígitos Ej: 9999999999999
BodegaInicial: 4 dígitos Ej: 0001
BodegaFinal: 13 dígitos Ej: 9999
Estado: 1 dígitos, D = Disponible, N = No disponible, T = Todos Ej: T

NombreArchivoExcelSalida: 50 caracteres, Nombre del archivo excel a generar  Ej: C:\SIIWI01\SerialesBodega.xlsx


Ejemplo GETBSRL:

ExcelSIIGO C:\SIIWI01\ 2018 GETBSRL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log S * zzzzzzzzzzzzzzzzzzzzzzzzz 0010001000001 9999999999999 0000 9999 T C:\SIIWI01\SerialesBodega.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


======================================================================================================================================================
Interfaces Histórico de Novedades
======================================================================================================================================================
GETHN :Extraer Histórico de novedades

ExcelSIIGO RutaEmpresa Año GETHN Norma Usuario Clave NombreLog TipoNovedad Modelo CentroCostoInicial CentroCostoFinal SubCentroCostoInicial SubCentroCostoFinal TerceroInicial TerceroFinal FechaInicial FechaFinal CargoInicial CargoFinal NombreArchivoExcelSalida

TipoNOvedad: CC = Cambio centro de costo , VA = Vacaciones, SU = Cambio de sueldo Ej: CC
Modelo: Modelo previamente definido en ruta: Recursos Humanos > Interfases > Exportación > Definición de Modelos
CentroCostoInicial: 4 dígitos Ej: 0000
CentroCostoFinal: 4 dígitos Ej: 9999
SubCentroCostoInicial: 3 dígitos Ej: 000
SubCentroCostoFinal: 3 dígitos Ej: 999
TerceroInicial: 13 dígitos Ej: 1
TerceroFinal: 13 dígitos Ej: 9999999999999
FechaInicial: 4 dígitos, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 0517
FechaFinal: 4 dígitos, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 0530
CargoInicial: 4 dígitos Ej: 0001
CargoFinal: 4 dígitos Ej: 9999


Ejemplo GETHN:

ExcelSIIGO C:\SIIWI01\ 2019 GETHN L ADMON 1111 C:\SIIWI01\LOGS\ExcelSiigo.log CC 1 0000 9999 000 999 1 9999999999999 0101 1231 0 999 C:\SIIWI01\novnomina.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


======================================================================================================================================================
Interfaces de empleados
======================================================================================================================================================

GETEMPL :Extraer empleados

ExcelSIIGO RutaEmpresa Año GETEMPL Norma Usuario Clave NombreLog ConDatos EmpleadoInicial EmpleadoFinal FechaAperturaInicial FechaAperturaFinal IncluyeRetirados NombreArchivoExcelSalida

ConDatos: 1 Carácter, N = Generar Solo Encabezado, S = Tomar datos de SIIGO Ej: S
EmpleadoInicial: 13 dígitos Ej: 1
EmpleadoFinal: 13 dígitos Ej: 9999999999999
FechaAperturaInicial: 8 dígitos, 4 dígitos = Año Inicial, 2 dígitos = Mes Inicial, 2 dígitos = Dia Inicial  Ej: 20210517
FechaAperturaFinal: 8 dígitos, 4 dígitos = Año Final, 2 dígitos = Mes Final, 2 dígitos = Dia Final  Ej: 20210530
IncluyeRetirados: 1 Carácter, N = No incluye Retirados, S = Si incluye Retirados Ej: S


Ejemplo GETEMPL:

ExcelSIIGO C:\SIIWI01\ 2022 GETEMPL L ADMON 1111 C:\SIIWI01\LOGS\ExcelSiigo.log S 1 9999999999999 20000101 20001231 S C:\SIIWI01\Empleados.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


PUSHEMPL :Importar Empleados a SIIGO

ExcelSIIGO RutaEmpresa Año PUSHEMPL Norma Usuario Clave NombreLog NombreArchivoExcelEntrada Ruta\nombrelogerrores

NombreArchivoExcelEntrada: 50 caracteres, Nombre del archivo excel que contiene la información a importar  Ej: C:\SIIWI01\Empleados.xlsx
Ruta\nombre log errores : Ruta donde se desea dejar log de errores si existen en los datos

IMPORTANTE:
Recuerde que el resultado de la importación quedará en la carpeta TEMP de la empresa correspondiente.


Ejemplo PUSHEMPL:

ExcelSIIGO C:\SIIWI01\ 2022 PUSHEMPL L Usuario Clave C:\SIIWI01\LOGS\ExcelSiigo.log C:\SIIWI01\Empleados.xlsx C:\SIIWI01\LOGS\ErrorEmpleados.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------

======================================================================================================================================================
Interfaces de Novedades
======================================================================================================================================================
GETNOV : Extraer Novedades de Nómina

ExcelSIIGO RutaEmpresa Año GETNOV Norma Usuario Clave NombreLog TipoNovedad NombreArchivoExcelSalida

TipoNovedad: C = Novedades de Cesantias,L = Novedades de Licencias,P = Anticipo de Primas,E = Embargos,R = Préstamos,A = Ahorros,I = Novedades de Incapacidad,V = Novedades de Vacaciones,G = Novedaddes Generales Ej: V

Ejemplo GETNOV:

ExcelSIIGO C:\SIIWI01\ 2019 GETNOV L ADMON 1111 C:\SIIWI01\LOGS\ExcelSiigo.log V C:\SIIWI01\novedadvac.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


======================================================================================================================================================
Interfaces de Informes
======================================================================================================================================================
GETINF : Extraer Informes

ExcelSIIGO RutaEmpresa Año GETINF Norma Usuario Clave NombreLog TipoInforme NitInicial NitFinal MesInicial MesFinal NombreArchivoExcelSalida

TipoInforme: B = Balance de comprobación por tercero

TerceroInicial: 13 dígitos Ej: 1
TerceroFinal: 13 dígitos Ej: 9999999999999
MesInicial: 2 dígitos Ej: 03
MesFinal: 02 dígitos Ej: 12


Ejemplo GETINF: (B)

ExcelSIIGO C:\SIIWI01\ 2019 GETINF L ADMON 1111 C:\SIIWI01\LOGS\ExcelSiigo.log B 1 9999999999999 03 12 C:\SIIWI01\BALANCEPORTERCEROS.xls
------------------------------------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------------------------------

TipoInforme: BCC = Balance de comprobación por cuenta

CuentaInicial: 10 dígitos Ej: 1
CuentaFinal: 10 dígitos Ej: 9999999999
MesInicial: 2 dígitos Ej: 03
MesFinal: 02 dígitos Ej: 12


Ejemplo GETINF: (BCC)

ExcelSIIGO C:\SIIWI01\ 2019 GETINF L ADMON 1111 C:\SIIWI01\LOGS\ExcelSiigo.log B 1 9999999999 03 12 C:\SIIWI01\BALANCEPORCUENTA.xlsx
------------------------------------------------------------------------------------------------------------------------------------------------------


IMPORTANTE:

Si en el parámetro NombreArchivoExcelSalida no se especifica una ruta, el archivo quedará en la carpeta de documentos del usuario.
