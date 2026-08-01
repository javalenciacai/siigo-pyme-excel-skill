# Errores de ExcelSIIGO.exe y recuperación

## Códigos conocidos

| Código | Mensaje                                              | Causa probable                                          | Solución                                                                 |
|--------|------------------------------------------------------|---------------------------------------------------------|--------------------------------------------------------------------------|
| `070`  | Empresa no se encuentra instalada                    | `RutaEmpresa` no apunta a una empresa SIIGO válida      | Verificar `SIIGO_EMPRESA` (debe ser exactamente 11 chars y terminar en `\`) y que la carpeta contenga los archivos de empresa (`*.gnt`, `*.dat`, etc.) |
| (vacío)| El CLI termina sin imprimir nada                     | Empresa abierta en otra sesión, o licencia no encontrada| Cerrar cualquier ventana de SIIGO Pyme abierta; verificar licencia con `Actualizador.exe` |
| `XXX Archivo no encontrado`  | XLSX de entrada/salida inexistente         | Ruta mal escrita o sin permisos                         | Validar ruta antes de invocar; usar rutas absolutas                       |
| `Acceso denegado`           | Permisos insuficientes sobre archivos/carpeta | Usuario sin permisos de lectura/escritura        | Ejecutar como admin o ajustar permisos NTFS                              |
| `Licencia vencida`          | Licencia SIIGO caducada                            | No se renovó la suscripción                            | Renovar; correr `Actualizador.exe` para descargar nueva licencia          |
| Salida vacía / .xlsx corrupto | Proceso cortado a media ejecución          | Memoria insuficiente, antivirus, o crash de SIIGO       | Revisar .LOG; liberar memoria; reintentar; verificar antivirus (excluir `C:\Siigo\`) |
| `Encabezados inválidos`     | XLSX no tiene las columnas esperadas                | Plantilla incorrecta o modificado a mano                | Regenerar plantilla con `excel-siigo.sh template <FUNCION>`               |

## Procedimiento general de diagnóstico

1. Ejecuta `bash scripts/check-prereqs.sh`. Si falla, corregir lo que indique.
2. Ejecuta el comando con `ConDatos=N` para validar que la conexión con
   SIIGO funciona sin tocar datos.
3. Si la operación destructiva (PUSH*) falla, revisa primero:
   - El archivo de log de errores XLSX.
   - La carpeta `TEMP` de la empresa (resultado parcial).
   - El .LOG principal en `SIIGO_LOGS`.
4. Si nada ayuda, ejecuta el comando a mano en una consola Windows con la
   misma sintaxis del manual y captura el mensaje literal.

## Patrones en el .LOG a vigilar

Los wrappers usan `scripts/parse-log.py` para extraer estas señales:

- `ERROR` → marca `log_errors`.
- `070` → marca `log_errors`.
- Líneas con `***` o `=====` → separadores informativos (ignorar).
- Líneas vacías entre secciones → ignorar.

## Errores del wrapper (no del CLI)

| Mensaje del wrapper                              | Causa                                                  |
|--------------------------------------------------|--------------------------------------------------------|
| `ExcelSIIGO.exe no encontrado en <ruta>`         | `SIIGO_EXE` apunta a un binario inexistente.           |
| `Faltan variables: SIIGO_USUARIO, SIIGO_CLAVE`   | No se exportaron las credenciales.                     |
| `Operación destructiva requiere --yes`           | Llamada a PUSH* sin confirmación.                      |
| `Comando excede 200 caracteres`                  | La línea de comando supera el límite de Windows.       |
| `No se pudo escribir <archivo>`                  | Carpeta LOGS sin permisos o llena.                     |

## Contacto con soporte SIIGO

Si el error es del propio CLI (no documentado arriba):

- Portal de clientes: https://portaldeclientes.siigo.com/
- Sub-portal Pyme: https://siigopyme2.portaldeclientes.siigo.com/
- Teléfono soporte Colombia: ver portal oficial.

Incluye siempre:

1. Versión de `EXCELSIIGO.exe` (clic derecho → Propiedades → Detalles).
2. Versión de SIIGO Pyme (menú Ayuda → Acerca de).
3. Comando completo que ejecutaste.
4. Contenido íntegro del .LOG resultante.
