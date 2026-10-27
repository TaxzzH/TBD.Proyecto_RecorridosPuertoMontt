/* ---------- 4. TRIGGER A NIVEL DE FILA ----------
   No consulta la tabla propia, por eso no cae en ORA-04091. */
CREATE OR REPLACE TRIGGER trg_valida_horario_entrada_salida
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

-- Horario de Entrada anterior a la Salida
INSERT INTO Registro_Recorrido_Bus (
    ID, 
    Hora_Ejecucion_Entrada, 
    Hora_Ejecucion_Salida, 
    Fecha_Recorrido, 
    Datos_Conductor_RUT, 
    Carril_Entrada_ID, 
    Carril_Salida_ID, 
    Recorridos_ID, 
    Horario_Entrada_ID, 
    Horario_Salida_ID, 
    Bus_Patente) VALUES (
        61, 
        TO_DATE('14/09/26 08:00', 'DD/MM/YY HH24:MI'), 
        TO_DATE('14/09/26 07:10', 'DD/MM/YY HH24:MI'), 
        TO_DATE('14/09/26', 'DD/MM/YY'), 
        '10101010-1', 
        1, 
        2, 
        1, 
        97, 
        99, 
        'HJKL10');