/* ============================================================
   EP2 BDY1103 - Terminal de Buses Puerto Montt
   Script final: package (publico/privado), funciones y
   procedimientos con y sin parametros, y 3 triggers
   (fila, sentencia y compuesto).
   Ejecutar DESPUES de SCRIPT_DB_RegistroRecorridos.sql
   y SCRIPT_INSERTS.sql.
   ============================================================ */
SET SERVEROUTPUT ON

/* ---------- 0. Limpieza de objetos anteriores ---------- */
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_valida_horario_recorrido'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_anti_traslape_horario';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_horario_terminal';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_valida_secuencia_viaje';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_validar_mantencion_bus';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_validar_licencia_conductor'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_registrar_salida_bus';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

/* ---------- 1. Tabla de bitacora (la usa el trigger de sentencia) ---------- */
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Bitacora_Registro PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Bitacora_Registro (
    ID         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Usuario    VARCHAR2(50) NOT NULL,
    Fecha_Hora DATE         NOT NULL,
    Operacion  VARCHAR2(10) NOT NULL
);

/* ---------- 2. PACKAGE: especificacion (elementos PUBLICOS) ---------- */
CREATE OR REPLACE PACKAGE pkg_gestion_terminales IS
    -- Funcion CON parametros
    FUNCTION fn_validar_mantencion_bus(p_patente IN VARCHAR2) RETURN NUMBER;

    -- Funcion SIN parametros
    FUNCTION fn_contar_mantenciones_vencidas RETURN NUMBER;

    -- Procedimiento CON parametros
    PROCEDURE sp_registrar_salida_bus(
        p_id           IN NUMBER,
        p_fecha        IN DATE,
        p_rut          IN VARCHAR2,
        p_patente      IN VARCHAR2,
        p_recorrido_id IN NUMBER,
        p_carril_ent   IN NUMBER,
        p_carril_sal   IN NUMBER,
        p_horario_ent  IN NUMBER,
        p_horario_sal  IN NUMBER
    );

    -- Procedimiento SIN parametros (proceso masivo: recorre todos los buses)
    PROCEDURE sp_reporte_mantenciones_vencidas;
END pkg_gestion_terminales;
/

/* ---------- 3. PACKAGE BODY (incluye elementos PRIVADOS) ---------- */
CREATE OR REPLACE PACKAGE BODY pkg_gestion_terminales IS

    -- PRIVADO: constante interna (no visible fuera del package)
    c_dias_aviso CONSTANT NUMBER := 30;

    -- PRIVADO: valida licencia activa y no vencida. 1 = valida, 0 = invalida
    FUNCTION fn_licencia_valida(p_rut IN VARCHAR2) RETURN NUMBER IS
        v_activa NUMBER;
        v_venc   DATE;
    BEGIN
        SELECT lc.estaActiva, lc.Fecha_Vencimiento
          INTO v_activa, v_venc
          FROM Datos_Conductor dc
          JOIN Licencias_Conductor lc ON dc.Licencias_Conductor_ID = lc.ID
         WHERE dc.RUT = p_rut;

        IF v_activa = 1 AND v_venc >= TRUNC(SYSDATE) THEN
            RETURN 1;
        END IF;
        RETURN 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;               -- conductor inexistente = no habilitado
    END fn_licencia_valida;

    -- PRIVADO: convierte (fecha + ID de Horarios) en un DATE real
    FUNCTION fn_hora_slot(p_fecha IN DATE, p_horario_id IN NUMBER) RETURN DATE IS
        v_slot Horarios.Hora_Slot%TYPE;
    BEGIN
        SELECT Hora_Slot INTO v_slot FROM Horarios WHERE ID = p_horario_id;
        RETURN TO_DATE(TO_CHAR(p_fecha, 'YYYY-MM-DD') || ' ' || v_slot, 'YYYY-MM-DD HH24:MI');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Horario inexistente: ' || p_horario_id);
    END fn_hora_slot;

    -- PUBLICA
    FUNCTION fn_validar_mantencion_bus(p_patente IN VARCHAR2) RETURN NUMBER IS
        v_venc DATE;
    BEGIN
        SELECT fm.Fecha_Vencimiento
          INTO v_venc
          FROM Bus b
          JOIN Ficha_Mantenimiento fm ON b.Ficha_Mantenimiento_ID = fm.ID
         WHERE b.Patente = p_patente;

        IF v_venc >= TRUNC(SYSDATE) THEN
            RETURN 1;
        END IF;
        RETURN 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;               -- bus inexistente = no apto
    END fn_validar_mantencion_bus;

    -- PUBLICA (sin parametros)
    FUNCTION fn_contar_mantenciones_vencidas RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_total
          FROM Bus b
          JOIN Ficha_Mantenimiento fm ON b.Ficha_Mantenimiento_ID = fm.ID
         WHERE fm.Fecha_Vencimiento < TRUNC(SYSDATE);
        RETURN v_total;
    END fn_contar_mantenciones_vencidas;

    -- PUBLICA
    PROCEDURE sp_registrar_salida_bus(
        p_id           IN NUMBER,
        p_fecha        IN DATE,
        p_rut          IN VARCHAR2,
        p_patente      IN VARCHAR2,
        p_recorrido_id IN NUMBER,
        p_carril_ent   IN NUMBER,
        p_carril_sal   IN NUMBER,
        p_horario_ent  IN NUMBER,
        p_horario_sal  IN NUMBER
    ) IS
        v_hora_entrada DATE;
        v_hora_salida  DATE;
    BEGIN
        -- RN-001: licencia del conductor (usa funcion PRIVADA)
        IF fn_licencia_valida(p_rut) = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'RN-001: licencia invalida o vencida para ' || p_rut);
        END IF;

        -- RN-002: mantencion del bus (usa funcion PUBLICA)
        IF fn_validar_mantencion_bus(p_patente) = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'RN-002: mantencion vencida o bus inexistente: ' || p_patente);
        END IF;

        -- Evaluar las horas en contexto PL/SQL antes del INSERT (evita error PLS-00231)
        v_hora_entrada := fn_hora_slot(p_fecha, p_horario_ent);
        v_hora_salida  := fn_hora_slot(p_fecha, p_horario_sal);

        INSERT INTO Registro_Recorrido_Bus (
            ID, Hora_Ejecucion_Entrada, Hora_Ejecucion_Salida, Fecha_Recorrido,
            Datos_Conductor_RUT, Carril_Entrada_ID, Carril_Salida_ID,
            Recorridos_ID, Horario_Entrada_ID, Horario_Salida_ID, Bus_Patente
        ) VALUES (
            p_id, v_hora_entrada, v_hora_salida, TRUNC(p_fecha),
            p_rut, p_carril_ent, p_carril_sal,
            p_recorrido_id, p_horario_ent, p_horario_sal, p_patente
        );

        DBMS_OUTPUT.PUT_LINE('OK: recorrido ' || p_id || ' registrado para bus ' || p_patente);
        -- Sin COMMIT: la transaccion la controla quien llama.
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20006, 'El ID de registro ' || p_id || ' ya existe.');
    END sp_registrar_salida_bus;

    -- PUBLICA (sin parametros, proceso masivo)
    PROCEDURE sp_reporte_mantenciones_vencidas IS
        v_n NUMBER := 0;
    BEGIN
        FOR r IN (SELECT b.Patente, fm.Fecha_Vencimiento
                    FROM Bus b
                    JOIN Ficha_Mantenimiento fm ON b.Ficha_Mantenimiento_ID = fm.ID
                   WHERE fm.Fecha_Vencimiento < TRUNC(SYSDATE) + c_dias_aviso
                   ORDER BY fm.Fecha_Vencimiento) LOOP
            v_n := v_n + 1;
            DBMS_OUTPUT.PUT_LINE(r.Patente || ' vence/vencio el ' || TO_CHAR(r.Fecha_Vencimiento, 'DD/MM/YYYY'));
        END LOOP;
        IF v_n = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ningun bus vencido ni por vencer en ' || c_dias_aviso || ' dias.');
        END IF;
    END sp_reporte_mantenciones_vencidas;

END pkg_gestion_terminales;
/

/* ---------- 4. TRIGGER A NIVEL DE FILA ----------
   No consulta la tabla propia, por eso no cae en ORA-04091. */
CREATE OR REPLACE TRIGGER trg_fila_secuencia_horas
BEFORE INSERT OR UPDATE ON Registro_Recorrido_Bus
FOR EACH ROW
DECLARE
    v_hora_ent Horarios.Hora_Slot%TYPE;
    v_hora_sal Horarios.Hora_Slot%TYPE;
BEGIN
    -- RN-006 / RN-007: el terminal opera entre 05:00 y 23:55
    -- (consulta otra tabla, Horarios, por lo que no hay tabla mutante)
    SELECT Hora_Slot INTO v_hora_ent FROM Horarios WHERE ID = :NEW.Horario_Entrada_ID;
    SELECT Hora_Slot INTO v_hora_sal FROM Horarios WHERE ID = :NEW.Horario_Salida_ID;
    IF v_hora_ent < '05:00' THEN
        RAISE_APPLICATION_ERROR(-20004, 'RN-006: la entrada (' || v_hora_ent || ') es antes de la apertura del terminal.');
    END IF;
    IF v_hora_sal > '23:55' THEN
        RAISE_APPLICATION_ERROR(-20004, 'RN-007: la salida (' || v_hora_sal || ') supera el cierre del terminal.');
    END IF;

    IF :NEW.Hora_Ejecucion_Entrada IS NOT NULL
       AND :NEW.Hora_Ejecucion_Salida IS NOT NULL
       AND :NEW.Hora_Ejecucion_Entrada >= :NEW.Hora_Ejecucion_Salida THEN
        RAISE_APPLICATION_ERROR(-20002, 'La hora de entrada debe ser anterior a la de salida.');
    END IF;
END;
/

/* ---------- 5. TRIGGER A NIVEL DE SENTENCIA ----------
   Se dispara UNA vez por sentencia, afecte a 1 o a 1000 filas. */
CREATE OR REPLACE TRIGGER trg_sentencia_bitacora
AFTER INSERT OR UPDATE OR DELETE ON Registro_Recorrido_Bus
DECLARE
    v_op VARCHAR2(10);
BEGIN
    IF INSERTING THEN v_op := 'INSERT';
    ELSIF UPDATING THEN v_op := 'UPDATE';
    ELSE v_op := 'DELETE';
    END IF;

    INSERT INTO Bitacora_Registro (Usuario, Fecha_Hora, Operacion)
    VALUES (USER, SYSDATE, v_op);
END;
/

/* ---------- 6. TRIGGER COMPUESTO: traslape de horario del bus ----------
   Un trigger de fila que consulte su propia tabla produce ORA-04091
   (tabla mutante) en UPDATE masivos o INSERT ... SELECT.
   Solucion: guardar las filas en memoria (AFTER EACH ROW) y validarlas
   cuando la tabla ya no esta mutando (AFTER STATEMENT). */
CREATE OR REPLACE TRIGGER trg_ct_traslape_bus
FOR INSERT OR UPDATE ON Registro_Recorrido_Bus
COMPOUND TRIGGER

    TYPE t_reg  IS RECORD (id NUMBER, patente VARCHAR2(10), fecha DATE, ent DATE, sal DATE);
    TYPE t_regs IS TABLE OF t_reg INDEX BY PLS_INTEGER;
    g_regs t_regs;

    AFTER EACH ROW IS
        v_r t_reg;
    BEGIN
        v_r.id      := :NEW.ID;
        v_r.patente := :NEW.Bus_Patente;
        v_r.fecha   := :NEW.Fecha_Recorrido;
        v_r.ent     := :NEW.Hora_Ejecucion_Entrada;
        v_r.sal     := :NEW.Hora_Ejecucion_Salida;
        g_regs(g_regs.COUNT + 1) := v_r;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_choques NUMBER;
    BEGIN
        FOR i IN 1 .. g_regs.COUNT LOOP
            IF g_regs(i).ent IS NOT NULL AND g_regs(i).sal IS NOT NULL THEN
                SELECT COUNT(*)
                  INTO v_choques
                  FROM Registro_Recorrido_Bus r
                 WHERE r.Bus_Patente     = g_regs(i).patente
                   AND r.Fecha_Recorrido = g_regs(i).fecha
                   AND r.ID             <> g_regs(i).id
                   AND r.Hora_Ejecucion_Entrada IS NOT NULL
                   AND r.Hora_Ejecucion_Salida  IS NOT NULL
                   AND g_regs(i).ent < r.Hora_Ejecucion_Salida
                   AND g_regs(i).sal > r.Hora_Ejecucion_Entrada;

                IF v_choques > 0 THEN
                    RAISE_APPLICATION_ERROR(-20003,
                        'RN-005: el bus ' || g_regs(i).patente || ' ya tiene un recorrido que se traslapa.');
                END IF;
            END IF;
        END LOOP;
    END AFTER STATEMENT;

END trg_ct_traslape_bus;
/

SHOW ERRORS

/* ============================================================
   PRUEBAS (cada una indica el resultado ESPERADO)
   Datos: conductor '10101010-1', bus 'HJKL10', recorrido 1,
   carriles 1 y 2, horarios 97='08:00', 99='08:10', 101='08:20'.
   Todo se deshace con ROLLBACK al final.
   ============================================================ */

PROMPT === T1: funcion SIN parametros. Esperado: 0 con los datos de ejemplo
SELECT pkg_gestion_terminales.fn_contar_mantenciones_vencidas AS vencidas FROM dual;

PROMPT === T2: funcion CON parametros usada desde SQL. Esperado: 1 para cada bus
SELECT Patente, pkg_gestion_terminales.fn_validar_mantencion_bus(Patente) AS apto
  FROM Bus FETCH FIRST 5 ROWS ONLY;

PROMPT === T3: registro valido. Esperado: mensaje OK
BEGIN
    pkg_gestion_terminales.sp_registrar_salida_bus(9001, DATE '2026-12-01', '10101010-1', 'HJKL10', 1, 1, 2, 97, 99);
END;
/

PROMPT === T4: mismo bus, misma fecha y mismo horario que T3. Esperado: ORA-20003 (trigger compuesto)
BEGIN
    pkg_gestion_terminales.sp_registrar_salida_bus(9002, DATE '2026-12-01', '10101010-1', 'HJKL10', 1, 1, 2, 97, 99);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
END;
/

PROMPT === T5: horas invertidas por INSERT directo. Esperado: ORA-20002 (trigger de fila)
BEGIN
    INSERT INTO Registro_Recorrido_Bus (ID, Hora_Ejecucion_Entrada, Hora_Ejecucion_Salida, Fecha_Recorrido,
        Datos_Conductor_RUT, Carril_Entrada_ID, Carril_Salida_ID, Recorridos_ID, Horario_Entrada_ID, Horario_Salida_ID, Bus_Patente)
    VALUES (9003, DATE '2026-12-02' + 8/24, DATE '2026-12-02' + 7/24, DATE '2026-12-02',
        '10101010-1', 1, 2, 1, 97, 99, 'HJKL10');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
END;
/

PROMPT === T10: horario fuera de operacion (slot 1 = 00:00). Esperado: ORA-20004 (RN-006)
BEGIN
    INSERT INTO Registro_Recorrido_Bus (ID, Hora_Ejecucion_Entrada, Hora_Ejecucion_Salida, Fecha_Recorrido,
        Datos_Conductor_RUT, Carril_Entrada_ID, Carril_Salida_ID, Recorridos_ID, Horario_Entrada_ID, Horario_Salida_ID, Bus_Patente)
    VALUES (9006, DATE '2026-12-05' + 1/24, DATE '2026-12-05' + 2/24, DATE '2026-12-05',
        '10101010-1', 1, 2, 1, 13, 25, 'HJKL10');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
END;
/

PROMPT === T6: licencia inactiva. Esperado: ORA-20001
BEGIN
    UPDATE Licencias_Conductor SET estaActiva = 0
     WHERE ID = (SELECT Licencias_Conductor_ID FROM Datos_Conductor WHERE RUT = '10101010-1');
    pkg_gestion_terminales.sp_registrar_salida_bus(9004, DATE '2026-12-03', '10101010-1', 'HJKL10', 1, 1, 2, 101, 103);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
END;
/
ROLLBACK;

PROMPT === T7: mantencion vencida + reporte masivo. Esperado: ORA-20002 y la patente en el reporte
BEGIN
    UPDATE Ficha_Mantenimiento SET Fecha_Vencimiento = TRUNC(SYSDATE) - 1
     WHERE ID = (SELECT Ficha_Mantenimiento_ID FROM Bus WHERE Patente = 'HJKL10');
    BEGIN
        pkg_gestion_terminales.sp_registrar_salida_bus(9005, DATE '2026-12-04', '10101010-1', 'HJKL10', 1, 1, 2, 101, 103);
    EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
    END;
    pkg_gestion_terminales.sp_reporte_mantenciones_vencidas;
END;
/
ROLLBACK;

PROMPT === T8: fila vs sentencia. Se insertan 3 filas y se actualizan con UN solo UPDATE
INSERT INTO Registro_Recorrido_Bus (ID, Hora_Ejecucion_Entrada, Hora_Ejecucion_Salida, Fecha_Recorrido,
    Datos_Conductor_RUT, Carril_Entrada_ID, Carril_Salida_ID, Recorridos_ID, Horario_Entrada_ID, Horario_Salida_ID, Bus_Patente)
SELECT 9100 + LEVEL, DATE '2026-12-10' + LEVEL + 8/24, DATE '2026-12-10' + LEVEL + 9/24, DATE '2026-12-10' + LEVEL,
       '10101010-1', 1, 2, 1, 97, 99, 'HJKL10'
  FROM dual CONNECT BY LEVEL <= 3;
DELETE FROM Bitacora_Registro;
UPDATE Registro_Recorrido_Bus SET Carril_Salida_ID = 3 WHERE ID BETWEEN 9101 AND 9103;
SELECT Operacion, COUNT(*) AS veces_disparado FROM Bitacora_Registro GROUP BY Operacion;
-- Esperado: el UPDATE afecto 3 filas (trigger de fila/compuesto procesa 3),
-- pero la bitacora registra UPDATE = 1 vez (trigger de sentencia).
-- Nota: el INSERT ... SELECT multifila tampoco produce ORA-04091 gracias al trigger compuesto.

PROMPT === T9: acceso privado. Esperado: PLS-00302 (no esta declarado en la especificacion)
BEGIN
    EXECUTE IMMEDIATE 'BEGIN DBMS_OUTPUT.PUT_LINE(pkg_gestion_terminales.fn_licencia_valida(''10101010-1'')); END;';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ESPERADO -> ' || SQLERRM);
END;
/
ROLLBACK;
