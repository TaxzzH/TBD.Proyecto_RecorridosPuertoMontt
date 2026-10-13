/*
DESCRIPCION BLOQUE ANONIMO:
Genera un Reporte Mensual de Recorridos por cada Conductor
*/
DECLARE

   TYPE t_recorrido_info IS RECORD (
      id_registro       NUMBER,
      fecha_recorrido   DATE,
      rut_conductor     VARCHAR(12),
      nombres_conductor VARCHAR2(100),
      patente_bus       VARCHAR(10),
      nombre_recorrido  VARCHAR2(100)
   );

   v_recorrido t_recorrido_info;

   -- 1er Cursor: Obtiene todos los conductores
   CURSOR c_conductores IS
      SELECT 
         rut,
         nombres,
         apellido_paterno
      FROM DATOS_CONDUCTOR;

    -- 2do Cursos (Complejo): realiza JOINs filtrando por RUT y Mes
   CURSOR c_recorridos(
      p_rut_conductor VARCHAR2, 
      p_mes_recorrido NUMBER
   ) IS
      SELECT 
         rrb.id,
         rrb.fecha_recorrido,
         dc.rut,
         dc.nombres || ' ' || dc.apellido_paterno AS nombres_conductor,
         rrb.bus_patente,
         rec.nombre_recorrido
      FROM REGISTRO_RECORRIDO_BUS rrb

      JOIN DATOS_CONDUCTOR dc ON rrb.datos_conductor_rut = dc.rut
      JOIN RECORRIDOS rec ON rrb.recorridos_id = rec.id
      WHERE dc.rut = p_rut_conductor
         AND EXTRACT(MONTH FROM rrb.fecha_recorrido) = p_mes_recorrido;

   -- Variables y Excepcion personalizada
   v_mes_consulta    NUMBER := 9; -- Mes a consultar (Septiembre)
   v_cont_recorridos NUMBER;
   e_sin_viajes      EXCEPTION;

BEGIN

   DBMS_OUTPUT.PUT_LINE('=================================================='  || chr(10) ||
                        '   REPORTE MENSUAL DE RECORRIDOS POR CONDUCTOR   '   || chr(10) ||
                        '==================================================');

   -- Iterar sobre cada conductor
   FOR r_cond IN c_conductores LOOP
      v_cont_recorridos := 0;
      
      DBMS_OUTPUT.PUT_LINE('--------------------------------------------------'              || chr(10) ||
                           'Conductor: ' || r_cond.nombres || ' ' || r_cond.apellido_paterno ||
                           ' | RUT: ' || r_cond.rut                                          || chr(10) ||
                           '--------------------------------------------------');

      -- Sub-bloque interno para aislamiento de excepciones
      BEGIN
         OPEN c_recorridos(r_cond.rut, v_mes_consulta);
         LOOP
            FETCH c_recorridos INTO 
               v_recorrido.id_registro,
               v_recorrido.fecha_recorrido,
               v_recorrido.rut_conductor,
               v_recorrido.nombres_conductor,
               v_recorrido.patente_bus,
               v_recorrido.nombre_recorrido;
               
            EXIT WHEN c_recorridos%NOTFOUND;

            v_cont_recorridos := v_cont_recorridos + 1;

            -- Impresion consumiendo los campos del RECORD
            DBMS_OUTPUT.PUT_LINE('  > [ID: ' || v_recorrido.id_registro || ']' ||
                                 ' Fecha: ' || TO_CHAR(v_recorrido.fecha_recorrido, 'DD/MM/YYYY') ||
                                 ' | Bus: ' || v_recorrido.patente_bus ||
                                 ' | Ruta: ' || v_recorrido.nombre_recorrido);
         END LOOP;
         CLOSE c_recorridos;

         -- Validar si el conductor tuvo recorridos
         IF v_cont_recorridos = 0 THEN
            RAISE e_sin_viajes;
         ELSE
            DBMS_OUTPUT.PUT_LINE('Total recorridos en el mes: ' || v_cont_recorridos);
         END IF;

      EXCEPTION
         -- Captura la excepcion de fila sin detener el loop principal
         WHEN e_sin_viajes THEN
            DBMS_OUTPUT.PUT_LINE('[ALERTA]: El conductor no registra recorridos en el mes.');
      END;

   END LOOP;

   DBMS_OUTPUT.PUT_LINE('=================================================='  || chr(10) ||
                        '              FIN DEL REPORTE                     '  || chr(10) ||
                        '==================================================');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[ERROR GLOBAL]: Ocurrio un error inesperado - ' || SQLERRM);
END;
/


/*
Creacion de nuevo conductor SIN registros para comprobar correcta ejecucion de la excepcion.
*/

INSERT INTO Datos_Conductor (
   RUT, 
   Nombres, 
   Apellido_Paterno, 
   Apellido_Materno, 
   Telefono, 
   Telefono_Emergencia, 
   Email, 
   Licencias_Conductor_ID) VALUES ('21111111-1', 'Pedrini', 'Gonzalini', 'Sotini', '+56911111112', '+56922222223', 'pedrini.gonzalini@buses.cl', 13);

Commit;
rollback;
