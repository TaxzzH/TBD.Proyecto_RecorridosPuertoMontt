CREATE OR REPLACE PACKAGE pkg_gestion_terminales IS
    -- Declaracion de variables globales o excepciones
    e_licencia_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_licencia_invalida, -20001);

    -- Funcion para validar si el bus tiene su mantenimiento al dia
    FUNCTION fn_validar_mantencion_bus(p_patente IN VARCHAR2) RETURN NUMBER;

    -- Procedimiento para registrar la salida de un bus
    PROCEDURE sp_registrar_salida_bus(
        p_id IN NUMBER,
        p_fecha IN DATE,
        p_rut IN VARCHAR2,
        p_patente IN VARCHAR2,
        p_recorrido_id IN NUMBER,
        p_carril_ent IN NUMBER,
        p_carril_sal IN NUMBER,
        p_horario_ent IN NUMBER,
        p_horario_sal IN NUMBER
    );
END pkg_gestion_terminales;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestion_terminales IS

    FUNCTION fn_validar_mantencion_bus(p_patente IN VARCHAR2) RETURN NUMBER IS
        v_fecha_vencimiento DATE;
    BEGIN
        SELECT fm.Fecha_Vencimiento
        INTO v_fecha_vencimiento
        FROM Bus b
        JOIN Ficha_Mantenimiento fm ON b.Ficha_Mantenimiento_ID = fm.ID
        WHERE b.Patente = p_patente;

        IF v_fecha_vencimiento >= TRUNC(SYSDATE) THEN
            RETURN 1; -- Verdadero (Valido)
        ELSE
            RETURN 0; -- Falso (Vencido)
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_validar_mantencion_bus;


    PROCEDURE sp_registrar_salida_bus(
        p_id IN NUMBER,
        p_fecha IN DATE,
        p_rut IN VARCHAR2,
        p_patente IN VARCHAR2,
        p_recorrido_id IN NUMBER,
        p_carril_ent IN NUMBER,
        p_carril_sal IN NUMBER,
        p_horario_ent IN NUMBER,
        p_horario_sal IN NUMBER
    ) IS
        v_licencia_activa NUMBER(1);
        v_licencia_vencimiento DATE;
        v_mantencion_valida NUMBER;
    BEGIN
        -- 1. Validar conductor (Excepcion predefinida NO_DATA_FOUND se dispararia sola si no existe)
        SELECT lc.estaActiva, lc.Fecha_Vencimiento
        INTO v_licencia_activa, v_licencia_vencimiento
        FROM Datos_Conductor dc
        JOIN Licencias_Conductor lc ON dc.Licencias_Conductor_ID = lc.ID
        WHERE dc.RUT = p_rut;

        IF v_licencia_activa = 0 OR v_licencia_vencimiento < TRUNC(SYSDATE) THEN
            RAISE e_licencia_invalida;
        END IF;

        -- 2. Validar mantencion del bus mediante la funcion
        v_mantencion_valida := fn_validar_mantencion_bus(p_patente);
        IF v_mantencion_valida = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'La ficha de mantencion del bus se encuentra vencida o el bus no existe.');
        END IF;

        -- 3. Insertar registro
        INSERT INTO Registro_Recorrido_Bus (
            ID, Hora_Ejecucion_Entrada, Hora_Ejecucion_Salida, Fecha_Recorrido,
            Datos_Conductor_RUT, Carril_Entrada_ID, Carril_Salida_ID,
            Recorridos_ID, Horario_Entrada_ID, Horario_Salida_ID, Bus_Patente
        ) VALUES (
            p_id, p_fecha + (p_horario_ent / 288), p_fecha + (p_horario_sal / 288), p_fecha,
            p_rut, p_carril_ent, p_carril_sal, p_recorrido_id, p_horario_ent, p_horario_sal, p_patente
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Recorrido registrado exitosamente.');
        
    EXCEPTION
        WHEN e_licencia_invalida THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: La licencia del conductor esta vencida o inhabilitada.');
            RAISE_APPLICATION_ERROR(-20001, 'La licencia del conductor esta vencida o inhabilitada.');
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: El ID del registro ya existe.');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            RAISE;
    END sp_registrar_salida_bus;

END pkg_gestion_terminales;
/
