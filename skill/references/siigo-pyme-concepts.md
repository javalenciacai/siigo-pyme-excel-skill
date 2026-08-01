# Glosario SIIGO Pyme

Términos y conceptos que usa SIIGO Pyme en su CLI y en su documentación.
Útil para entender los nombres de campos en los .xlsx generados.

## Maestros

- **Tercero**: cualquier persona natural o jurídica con la que la empresa
  tiene relación (clientes, proveedores, empleados, otros). Se identifica
  con un NIT/número de 13 dígitos. `GETTER` / `PUSHTER`.

- **Cuenta contable**: código PUC (Plan Único de Cuentas colombiano) de
  10 dígitos. Estructura: clase(1) + grupo(2) + cuenta(3) + subcuenta(4).
  Ej: `1105050100` = Caja general. `GETCTA` / `PUSHCTA`.

- **Producto / Inventario**: ítem del inventario. Código de 13 dígitos:
  línea(3) + grupo(4) + producto(6). `GETINV` / `PUSHINV`.

- **Activo fijo**: bien depreciable. Código de 9 dígitos. `GETACT` / `PUSHACT`.
  Agrupado en grupos (4 dígitos) — `GETGRA` / `PUSHGRA`.

- **Bodega / Ubicación**: sitio físico donde se almacena inventario.
  Bodega 4 dígitos, ubicación 3 dígitos. `GETTBO` / `PUSHTBO`.

- **Centro de costo / Sub-centro**: unidad organizacional para imputar
  gastos. 4 dígitos + 3 dígitos. `GETCOS` / `PUSHCOS`.

- **Vendedor**: persona que vende. Código de 4 dígitos. `GETVEN` / `PUSHVEN`.

- **Actividad económica (ICA)**: código CIIU de 5 dígitos para impuestos
  ICA municipales. `GETICA` / `PUSHICA`.

- **País / Ciudad**: maestro geográfico. País 3 dígitos, ciudad 4 dígitos.
  `GETCIU`.

## Documentos

- **Comprobante contable**: documento que respalda un movimiento.
  Identificado por tipo (Factura, Recibo, etc.) + código (3d) + número
  (11d). En `GETMOV` se filtran por tipo.

- **Tipo de comprobante**:
  - `F` = Factura
  - `*` = Todos
  - En `GETEXT`: `Z`=Orden de Pedido, `Y`=Orden de Compra, `V`=Cotización
  - (Otros tipos en SIIGO Pyme: N, C, R, A, G, P, etc. — consultar manual)

- **Documento extracontable**: documento comercial que NO genera
  movimiento contable (cotizaciones, pedidos). `GETEXT` / `PUSHEXT`.

- **Movimiento contable**: registro débito/crédito en cuentas PUC.
  `GETMOV` / `PUSHMOV`.

- **Modelo Básico**: formato simplificado para contabilizar un documento
  (sólo productos, sin moneda extranjera, sin AIU, etc.). Se activa con
  `ModeloBasico=S`. Documentado en §46-55 del manual oficial.

- **Saldo CxC / CxP**: deuda pendiente de un tercero a favor (CxC) o en
  contra (CxP) de la empresa. `GETSAL`.

- **Cartera**: conjunto de CxC y CxP. `GETSAL` extrae saldos.

## Normas contables

- **L** (Local): Plan Único de Cuentas colombiano estándar.
- **N** (NIIF): Normas Internacionales de Información Financiera.
- Una misma empresa puede mantener ambas normas en paralelo. Las funciones
  de movimiento y cuentas operan sobre la norma indicada.

## Parámetros típicos

- **FIni / FFin**: rango de fechas. Formato `MMDD` (4 dígitos) para
  movimientos/saldos; `YYYYMMDD` (8 dígitos) para terceros/empleados.

- **ConDatos** (`S`/`N`): `S` = el .xlsx se llena con datos reales;
  `N` = sólo encabezados (útil para generar plantillas).

- **NombreLog**: ruta del archivo .LOG que el CLI escribe con el resultado.

- **LogErrores** (PUSH*): ruta del .xlsx donde se depositan los registros
  rechazados durante la importación.

## Salidas

- **TEMP**: carpeta dentro de la empresa donde SIIGO deposita los
  resultados de las importaciones (PUSH*). Cada PUSH deja un .xlsx aquí
  con el resultado, incluso si fue exitoso.

- **.xlsx de salida** (GET*): el archivo con los datos extraídos. Si no
  se pasa ruta absoluta, queda en `C:\Users\<usuario>\Documents\`.

## Licencia

- **CtrlSIIGOLic.gnt** y **Actualizador.exe** gestionan la licencia.
- Una empresa sin licencia activa puede abrir la UI pero el CLI puede
  negarse a ejecutar ciertas funciones.
- El agente que invoque este skill debe asumir que la licencia está vigente
  y NO incluir lógica de renovación — eso es responsabilidad del usuario.
