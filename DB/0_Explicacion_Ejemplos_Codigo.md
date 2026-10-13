# Explicación de los Ejemplos de Código (v1.1.1)

El directorio `1.1.1_DB-v1` contiene cinco scripts fundamentales que se encargan de inicializar la base de datos, insertar datos de prueba y ejecutar procesos tanto lógicos como de consulta mediante SQL y PL/SQL. A continuación se explica detalladamente cada uno de los archivos:

---

## 1. `0_BORRAR_TODO.sql`
**Propósito:** Limpiar por completo el entorno de la base de datos de manera rápida y automatizada.

**Explicación del código:**
Utiliza un bloque anónimo de PL/SQL muy conciso:
- Ejecuta un bucle `FOR` implícito (cursor) que consulta la vista de sistema `user_tables` para obtener los nombres de todas las tablas pertenecientes al usuario actual.
- Por cada iteración, ensambla y ejecuta una sentencia SQL dinámica (`EXECUTE IMMEDIATE`) que elimina la tabla (`DROP TABLE... CASCADE CONSTRAINTS PURGE`). Esto asegura que se borren las tablas junto con todas sus llaves foráneas y datos, sin enviarlas a la papelera de reciclaje de Oracle.

---

## 2. `SCRIPT_DB_RegistroRecorridos.sql`
**Propósito:** Realizar el Levantamiento del Modelo de Datos (DDL).

**Explicación del código:**
- Crea en un orden secuencial las tablas primarias y secundarias requeridas para el negocio (`Bus`, `Datos_Conductor`, `Licencias_Conductor`, `Terminal`, `Registro_Recorrido_Bus`, etc.).
- Define sus tipos de datos, constraints `NOT NULL`, llaves primarias (`PRIMARY KEY`) y validaciones de tipo `CHECK` (por ejemplo, validar que `estaActiva` sea 0 o 1).
- Finalmente, mediante comandos `ALTER TABLE`, genera toda la integridad referencial creando las llaves foráneas (`FOREIGN KEY`) entre los módulos.

---

## 3. `SCRIPT_INSERTS.sql`
**Propósito:** Poblar masivamente la base de datos con datos de prueba, tanto manuales como automatizados.

**Explicación del código:**
- Contiene comandos `INSERT INTO` tradicionales para catálogos y entidades que requieren datos específicos, como direcciones concretas, conductores con RUT válidos y listados de buses con sus patentes.
- **Automatización con PL/SQL:** Destaca el uso de bloques anónimos con bucles `FOR` iterativos para insertar grandes volúmenes de datos sin necesidad de escribir cientos de líneas. 
  - Por ejemplo, usa un `FOR i IN 1..42 LOOP` para poblar los 42 carriles del Terminal de manera instantánea.
  - Genera 60 registros complejos para la tabla transaccional `Registro_Recorrido_Bus` iterando y utilizando funciones modulares (`MOD(i, ...)`) y funciones de ventana (`ROW_NUMBER() OVER (...)`) para rotar los conductores, buses, horarios y fechas, simulando así una operación real en la base de datos de forma matemática.

---

## 4. `BLOQUEANON_.ReporteMensual.sql`
**Propósito:** Demostrar el uso avanzado de PL/SQL para reportes, cumpliendo con la estructura de variables complejas, cursores maestro-detalle y manejo de excepciones.

**Explicación del código:**
- **Tipo de Dato Compuesto (RECORD):** Define el tipo `t_recorrido_info` y su variable asociada `v_recorrido` para empaquetar de forma estructurada los 6 campos necesarios al imprimir el reporte, mejorando el orden del código.
- **Cursor Maestro-Detalle:**
  - *Maestro:* Usa el cursor implícito `c_conductores` para recorrer (iterar) uno por uno todos los conductores registrados.
  - *Detalle:* Define un cursor explícito complejo (`c_recorridos`) que **recibe parámetros** (`p_rut_conductor` y `p_mes_recorrido`). En el cuerpo del bloque, este cursor se abre pasándole el RUT que arrojó la iteración actual del Maestro, filtrando eficientemente mediante `JOINs` únicamente los viajes correspondientes a ese conductor específico en el mes de septiembre.
- **Manejo Robusto de Excepciones:** Se declara la excepción personalizada `e_sin_viajes`. Si el cursor de detalle finaliza y el contador de viajes se mantuvo en 0, se arroja manualmente la excepción (`RAISE e_sin_viajes;`). Esto permite capturar el error y emitir un mensaje visual `[ALERTA]` de que ese conductor no trabajó este mes, **sin detener** el bucle global (por lo que el reporte continúa con el siguiente conductor de manera resiliente). 

---

## 5. `CONSULTA_Horarios.sql`
**Propósito:** Realizar una consulta de visualización de los horarios de salidas e ingresos de los recorridos.

**Explicación del código:**
Es una consulta de manipulación de datos (DML) de selección estándar pero con características analíticas y de presentación:
- Utiliza la función `TO_CHAR()` para darle a las fechas y horas registradas en sistema un formato amigable para el ser humano (`DD/MM/YYYY HH24:MI`).
- Emplea un bloque `CASE` (lógica condicional en SQL directo) que evalúa dinámicamente si el atributo `HORA_EJECUCION_SALIDA` está en nulo. De ser así, rotula virtualmente el estado del recorrido como 'PENDIENTE'; de lo contrario, lo marca como 'RECORRIDO INICIADO'.
- Asegura la consistencia ocultando registros huérfanos mediante la cláusula `WHERE ... IS NOT NULL`.
