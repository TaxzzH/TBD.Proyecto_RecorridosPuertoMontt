CREATE OR REPLACE FUNCTION fn_dias_revision_tecnica(p_patente IN VARCHAR2)
RETURN VARCHAR2
IS
    v_vencimiento DATE;
    v_dias        NUMBER;
BEGIN
    SELECT fm.Fecha_Vencimiento
      INTO v_vencimiento
      FROM Bus b
      JOIN Ficha_Mantenimiento fm ON b.Ficha_Mantenimiento_ID = fm.ID
     WHERE b.Patente = p_patente;

    v_dias := TRUNC(v_vencimiento) - TRUNC(SYSDATE);

    IF v_dias > 0 THEN
        RETURN 'Revision tecnica vigente: quedan ' || v_dias || ' dia(s) (vence el '
               || TO_CHAR(v_vencimiento, 'DD/MM/YYYY') || ').';
    ELSIF v_dias = 0 THEN
        RETURN 'ATENCION: la revision tecnica vence HOY.';
    ELSE
        RETURN 'ADVERTENCIA: revision tecnica VENCIDA hace ' || ABS(v_dias)
               || ' dia(s) (vencio el ' || TO_CHAR(v_vencimiento, 'DD/MM/YYYY') || ').';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Bus no encontrado: ' || p_patente;
END fn_dias_revision_tecnica;
/

/* Uso de Funcion */ 
SET SERVEROUTPUT ON;

DECLARE
    v_patente VARCHAR2(10) := 'HJKL19';
BEGIN
    -- 1. Caso real (con los datos cargados)
    DBMS_OUTPUT.PUT_LINE('1) Real:        ' || fn_dias_revision_tecnica(v_patente));

    -- 2. Bus que no existe
    DBMS_OUTPUT.PUT_LINE('2) Inexistente: ' || fn_dias_revision_tecnica('XXXX00'));

    -- 3. Simular "vence hoy"
    UPDATE Ficha_Mantenimiento
       SET Fecha_Vencimiento = TRUNC(SYSDATE)
     WHERE ID = (SELECT Ficha_Mantenimiento_ID FROM Bus WHERE Patente = v_patente);
    DBMS_OUTPUT.PUT_LINE('3) Vence hoy:   ' || fn_dias_revision_tecnica(v_patente));

    -- 4. Simular "vencida hace 5 dias"
    UPDATE Ficha_Mantenimiento
       SET Fecha_Vencimiento = TRUNC(SYSDATE) - 5
     WHERE ID = (SELECT Ficha_Mantenimiento_ID FROM Bus WHERE Patente = v_patente);
    DBMS_OUTPUT.PUT_LINE('4) Vencida:     ' || fn_dias_revision_tecnica(v_patente));

    ROLLBACK;  -- deshace las fechas simuladas
END;
/