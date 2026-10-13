/*
Demostracion del uso de VARRAY para la validacion en memoria de tipos de licencia.
*/
DECLARE
    -- Declaracion del tipo VARRAY (limite de 5 elementos maximo)
    TYPE t_tipos_licencia IS VARRAY(5) OF VARCHAR2(10);
    
    -- Inicializacion del arreglo con los datos
    v_licencias_validas t_tipos_licencia := t_tipos_licencia('Clase A1', 'Clase A2', 'Clase A3', 'Clase A4', 'Clase A5');
    
    v_licencia_a_buscar VARCHAR2(10) := 'Clase A3';
    v_es_valida BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Validando tipo de licencia en memoria (VARRAY)...');
    
    -- Iteracion sobre el VARRAY
    FOR i IN 1..v_licencias_validas.COUNT LOOP
        IF v_licencias_validas(i) = v_licencia_a_buscar THEN
            v_es_valida := TRUE;
            EXIT;
        END IF;
    END LOOP;
    
    IF v_es_valida THEN
        DBMS_OUTPUT.PUT_LINE('El tipo de licencia ' || v_licencia_a_buscar || ' SI esta permitido en el sistema.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('El tipo de licencia ' || v_licencia_a_buscar || ' NO esta permitido.');
    END IF;
END;
/
