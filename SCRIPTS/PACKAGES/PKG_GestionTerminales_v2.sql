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
