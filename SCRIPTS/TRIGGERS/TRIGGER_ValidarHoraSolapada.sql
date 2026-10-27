CREATE OR REPLACE TRIGGER trg_valida_horario_solapado
BEFORE INSERT OR UPDATE ON Registro_Recorrido_Bus
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Validar que no exista traslape con otro recorrido del mismo bus en la misma fecha
    SELECT COUNT(*)
    INTO v_count
    FROM Registro_Recorrido_Bus
    WHERE Bus_Patente = :NEW.Bus_Patente
      AND Fecha_Recorrido = :NEW.Fecha_Recorrido
      AND ID != NVL(:NEW.ID, -1) -- Excluir el registro actual si es un UPDATE
      AND (
          (:NEW.Hora_Ejecucion_Entrada BETWEEN Hora_Ejecucion_Entrada AND Hora_Ejecucion_Salida)
          OR 
          (:NEW.Hora_Ejecucion_Salida BETWEEN Hora_Ejecucion_Entrada AND Hora_Ejecucion_Salida)
          OR
          (Hora_Ejecucion_Entrada BETWEEN :NEW.Hora_Ejecucion_Entrada AND :NEW.Hora_Ejecucion_Salida)
      );

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'El bus ya se encuentra asignado a un recorrido en ese horario (traslape).');
    END IF;
END;
/


-- Registro que solapa con otro
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
        62, 
        TO_DATE('14/09/26 08:00', 'DD/MM/YY HH24:MI'), 
        TO_DATE('14/09/26 08:10', 'DD/MM/YY HH24:MI'), 
        TO_DATE('14/09/26', 'DD/MM/YY'), 
        '10101010-1', 
        1, 
        2, 
        1, 
        97, 
        99, 
        'HJKL10');


